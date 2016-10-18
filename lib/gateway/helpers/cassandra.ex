defmodule Gateway.Helpers.Cassandra do
  @moduledoc """
  Helper for working with Cassandra
  """
  alias Cassandra.Connection

  @insert_query """
    insert into logs (id, created_at, idempotency_key, ip_address, request) values (?, toTimestamp(now()), ?, ?, ?);
  """

  @update_query """
    update logs set response = ?, latencies = ?, status_code = ? where id = ?;
  """

  defp init do
    cassandra_hostname = Confex.get(:cassandra, :hostname)
    cassandra_port = Confex.get(:cassandra, :port)
    cassandra_keyspace = Confex.get(:cassandra, :keyspace)
    {:ok, cassandra_conn} = Connection.start_link [
      hostname: cassandra_hostname,
      port: cassandra_port,
      keyspace: cassandra_keyspace
    ]
    cassandra_conn
  end

  defp get_query(cassandra_conn, :insert) do
    Connection.prepare cassandra_conn, @insert_query
  end

  defp get_query(cassandra_conn, :update) do
    Connection.prepare cassandra_conn, @update_query
  end

  def write_logs(records, type) do
    cassandra_conn = init

    {:ok, query} = get_query(cassandra_conn, type)

    records
    |> Enum.map(&Task.async(fn -> Connection.execute(cassandra_conn, query, &1) end))
    |> Enum.map(&Task.await/1)
  end
end
