defmodule Annon.Monitoring.MetricsCollector do
  @moduledoc """
  This module provides helper functions to persist meaningful metrics to StatsD or DogstatsD servers.

  Code is based on [Statix](https://github.com/lexmag/statix) library.
  """
  use GenServer
  alias AnnonMonitoring.MetricsCollector.Packet

  defstruct [:sock, :header, :config]

  @doc """
  Starts a metric collector process.

  `conn_opts` accepts connection arg
  """
  def start_link(conn_opts) do
    GenServer.start_link(__MODULE__, conn_opts, name: __MODULE__)
  end

  @doc false
  def init(conn_opts) do
    enabled? = Keyword.get(conn_opts, :enabled?, true)
    host = conn_opts |> Keyword.get(:host, "127.0.0.1") |> String.to_char_list()
    port = Keyword.get(conn_opts, :port, 8125)
    sink = Keyword.get(conn_opts, :sink, nil)
    namespace = Keyword.get(conn_opts, :namespace, nil)
    send_tags? = Keyword.get(conn_opts, :send_tags?, true)

    {:ok, address} = :inet.getaddr(host, :inet)
    header = Packet.header(address, port)

    {:ok, socket} = :gen_udp.open(0, [active: false])

    {:ok, %{
      enabled?: enabled?,
      send_tags?: send_tags?,
      header: [header | "#{namespace}."],
      socket: socket,
      sink: sink
    }}
  end

  def increment(key, val \\ 1, options \\ []) when is_number(val) do
    transmit(:counter, key, val, options)
  end

  def decrement(key, val \\ 1, options \\ []) when is_number(val) do
    transmit(:counter, key, [?-, to_string(val)], options)
  end

  def gauge(key, val, options \\ [] ) do
    transmit(:gauge, key, val, options)
  end

  def histogram(key, val, options \\ []) do
    transmit(:histogram, key, val, options)
  end

  def timing(key, val, options \\ []) do
    transmit(:timing, key, val, options)
  end

  @doc false
  def transmit(type, key, val, options) when (is_binary(key) or is_list(key)) and is_list(options) do
    sample_rate = Keyword.get(options, :sample_rate)

    if is_nil(sample_rate) or sample_rate >= :rand.uniform() do
      GenServer.cast(__MODULE__, {:transmit, type, key, to_string(val), options})
    end

    :ok
  end

  @doc false
  def handle_cast({:transmit, _type, _key, _value, _options}, %{enabled?: false} = state),
    do: {:noreply, state}

  # Transmits message to a sink
  @doc false
  def handle_cast({:transmit, type, key, value, options}, %{sink: sink} = state) when is_list(sink) do
    %{header: header} = state
    packet = %{type: type, key: key, value: value, options: options, header: header}
    {:noreply, %{state | sink: [packet | sink]}}
  end

  # Transmits message to a StatsD server
  @doc false
  def handle_cast({:transmit, type, key, value, options}, state) do
    %{header: header, socket: socket, send_tags?: send_tags?} = state

    packet = Packet.build(header, type, key, value, send_tags?, options)
    Port.command(socket, packet)

    receive do
      {:inet_reply, _port, status} -> status
    end

    {:noreply, state}
  end

  @doc false
  def handle_call(:flush, _from, state) do
    {:reply, :ok, state}
  end
end
