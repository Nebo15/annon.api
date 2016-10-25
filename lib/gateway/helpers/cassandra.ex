defmodule Gateway.Helpers.Cassandra do
  @moduledoc """
  Helper for working with Cassandra
  """
  alias Gateway.DB.Cassandra

  @select_all_query """
    select * from gateway.logs where token(id) > token(?) and token(id) < token(?) limit ?;
  """

  @select_by_id_query """
    select * from gateway.logs where id = ?;
  """

  @delete_by_id_query """
    delete from gateway.logs where id = ?;
  """

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

  defp get_query(:create_keyspace) do
    Cassandra.prepare @create_keyspace_query
  end

  defp get_query(:create_logs_table) do
    Cassandra.prepare @create_logs_table_query
  end

  defp get_query(:select_all) do
    Cassandra.prepare @select_all_query
  end

  defp get_query(:select_by_id) do
    Cassandra.prepare @select_by_id_query
  end

  defp get_query(:delete_by_id) do
    Cassandra.prepare @delete_by_id_query
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
    |> Enum.map(&Task.await/1)
  end
end
