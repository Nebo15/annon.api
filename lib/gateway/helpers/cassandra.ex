defmodule Gateway.Helpers.Cassandra do
  @moduledoc """
  Helper for working with Cassandra
  """
  alias Cassandra.Connection

  @insert_query """
    insert into gateway.logs (id, created_at, idempotency_key, ip_address, request)
      values (?, toTimestamp(now()), ?, ?, ?);
  """

  @update_query """
    update gateway.logs set response = ?, latencies = ?, status_code = ? where id = ?;
  """

  @create_keyspace_query """
    create keyspace if not exists gateway with replication = {'class' : 'SimpleStrategy', 'replication_factor' : 1};
  """

  @create_logs_table_query """
    create table if not exists gateway.logs (
      id text,
      created_at timestamp,
      idempotency_key text,
      ip_address inet,
      request blob,
      response blob,
      latencies blob,
      status_code int,
      PRIMARY KEY (id)
    );
  """

  defp get_query(cassandra_conn, :create_keyspace) do
    Connection.prepare cassandra_conn, @create_keyspace_query
  end

  defp get_query(cassandra_conn, :create_logs_table) do
    Connection.prepare cassandra_conn, @create_logs_table_query
  end

  defp get_query(cassandra_conn, :insert_logs) do
    Connection.prepare cassandra_conn, @insert_query
  end

  defp get_query(cassandra_conn, :update_logs) do
    Connection.prepare cassandra_conn, @update_query
  end

  def execute_query(records, type) do
    cassandra_conn = Process.whereis Cassandra

    {:ok, query} = get_query(cassandra_conn, type)

    records
    |> Enum.map(&Task.async(fn -> Connection.execute(cassandra_conn, query, &1) end))
    |> Enum.map(&Task.await/1)
  end
end
