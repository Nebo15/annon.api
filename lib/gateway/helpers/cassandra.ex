defmodule Gateway.Helpers.Cassandra do
  @moduledoc """
  Helper for working with Cassandra
  """
<<<<<<< HEAD
  alias Gateway.DB.Cassandra

  @select_by_id_query """
    select * from gateway.logs where id = ?;
  """
=======
  alias Cassandra.Connection
>>>>>>> 8e929e9b63fbaa634935199c31d2f51e0d9376a6

  @insert_query """
    insert into gateway.logs (id, created_at, idempotency_key, ip_address, request)
      values (?, toTimestamp(now()), ?, ?, ?);
  """

  @update_query """
    update gateway.logs set api = ?, consumer = ?, response = ?, latencies = ?, status_code = ? where id = ?;
  """

  @create_keyspace_query """
    create keyspace if not exists gateway with replication = {'class' : 'SimpleStrategy', 'replication_factor' : 1};
  """

  @create_logs_table_query """
    create table if not exists gateway.logs (
      id text,
      api blob,
      consumer blob,
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

<<<<<<< HEAD
  defp get_query(:create_keyspace) do
    Cassandra.prepare @create_keyspace_query
  end

  defp get_query(:create_logs_table) do
    Cassandra.prepare @create_logs_table_query
  end

  defp get_query(:select_by_id) do
    Cassandra.prepare @select_by_id_query
  end

  defp get_query(:insert_logs) do
    Cassandra.prepare @insert_query
  end

  defp get_query(:update_logs) do
    Cassandra.prepare @update_query
  end

  def execute_query(records, type) do
    {:ok, query} = get_query(type)

    records
    |> Enum.map(&Task.async(fn -> Cassandra.execute(query, values: &1) end))
=======
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
>>>>>>> 8e929e9b63fbaa634935199c31d2f51e0d9376a6
    |> Enum.map(&Task.await/1)
  end
end
