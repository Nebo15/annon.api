defmodule Annon.Requests.LogWriter do
  @moduledoc """
  This module provides interface to synchronously or asynchronously create Log Entries.
  """
  use GenServer
  alias Annon.Requests.Log
  alias Ecto.Changeset
  require Logger

  @doc """
  Start a LogWriter worker.
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc false
  def init(_) do
    {:ok, [subscribers: []]}
  end

  @doc """
  Creates a Request.

  ## Examples

      iex> create_request(%{field: value})
      {:ok, %Annon.Requests.Request{}}

      iex> create_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_request(attrs) do
    Log.create_request(attrs)
  end

  @doc """
  Asynchronously creates a Request.
  If request insert operations is failed, error is logged to a console.

  ## Examples

      iex> create_request(%{field: value})
      :ok

      iex> create_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_request_async(attrs) do
    case Log.change_request(attrs) do
      %Changeset{valid?: false} = changeset ->
        {:error, changeset}
      changeset ->
        GenServer.cast(__MODULE__, {:insert_request, changeset})
        :ok
    end
  end

  def subscribe(name_or_pid) do
    GenServer.call(__MODULE__, {:subscribe, name_or_pid})
  end

  def unsubscribe(name_or_pid) do
    GenServer.call(__MODULE__, {:unsubscribe, name_or_pid})
  end

  @doc false
  def handle_cast({:insert_request, changeset}, opts) do
    case Log.insert_request(changeset) do
      {:ok, _request} = message ->
        maybe_notify_subscribers(message, opts)
        {:noreply, opts}
      {:error, changeset} = message ->
        Logger.error("Failed to log request: #{inspect changeset}")
        maybe_notify_subscribers(message, opts)
        {:noreply, opts}
    end
  end

  @doc false
  def handle_call({:subscribe, name_or_pid}, _from, opts) do
    subscribers =
      opts
      |> Keyword.get(:subscribers)
      |> List.insert_at(0, name_or_pid)

    opts = [subscribers: subscribers]
    {:reply, opts, opts}
  end

  @doc false
  def handle_call({:unsubscribe, name_or_pid}, _from, opts) do
    subscribers =
      opts
      |> Keyword.get(:subscribers)
      |> List.delete(name_or_pid)

    opts = [subscribers: subscribers]
    {:reply, opts, opts}
  end

  defp maybe_notify_subscribers(message, opts) do
    case Keyword.fetch(opts, :subscribers) do
      :error ->
        :ok
      {:ok, subscribers} ->
        Enum.map(subscribers, &send(&1, message))
    end
  end
end
