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

  `start_link` accepts optional `opts` as `Keyword`:
    * `name` - name for a worker process;
    * `subscriber` - name or pid of a process that wants to be notified when log is
    written with `create_request_async/1`.
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc false
  def init(opts) do
    {:ok, opts}
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

  Accepts optional `opts` as `Keyword`:
    * `name` - name or pid of a worker process.

  ## Examples

      iex> create_request(%{field: value})
      :ok

      iex> create_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_request_async(attrs, opts \\ []) do
    name_or_pid = Keyword.get(opts, :name, __MODULE__)
    case Log.change_request(attrs) do
      %Changeset{valid?: false} = changeset ->
        {:error, changeset}
      changeset ->
        GenServer.cast(name_or_pid, {:insert_request, changeset})
        :ok
    end
  end

  @doc false
  def handle_cast({:insert_request, changeset}, opts) do
    case Log.insert_request(changeset) do
      {:ok, _request} = message ->
        maybe_notify_subscriber(message, opts)
        {:noreply, opts}
      {:error, changeset} = message ->
        Logger.error("Failed to log request: #{inspect changeset}")
        maybe_notify_subscriber(message, opts)
        {:noreply, opts}
    end
  end

  defp maybe_notify_subscriber(message, opts) do
    case Keyword.fetch(opts, :subscriber) do
      :error -> :ok
      {:ok, subscriber} ->
        send(subscriber, message)
    end
  end
end
