defmodule Gateway.Helpers.Cassandra do
  @moduledoc """
  Helper for working with Cassandra
  """
  alias Gateway.DB.Cassandra

<<<<<<< HEAD
  @select_all_query """
    select * from gateway.logs where token(id) > token(?) and token(id) < token(?) limit ?;
  """
=======
  @truncate "TRUNCATE gateway.logs;"
>>>>>>> 5328b06fef20cfa7600cd48ad39761d5b9e79f63

  @select_by_id_query """
    SELECT * FROM gateway.logs WHERE id = ?;
  """

  @select_by_idempotency_key_query """
    SELECT * FROM gateway.logs WHERE idempotency_key = ? LIMIT 1 ALLOW FILTERING;
  """

  @delete_by_id_query """
    delete from gateway.logs where id = ?;
  """

  @insert_query """
    INSERT INTO gateway.logs (id, created_at, idempotency_key, ip_address, request)
      values (?, toTimestamp(now()), ?, ?, ?);
  """

  @update_query """
    UPDATE gateway.logs SET api = ?, consumer = ?, response = ?, latencies = ?, status_code = ? WHERE id = ?;
  """

  @create_keyspace_query """
    CREATE keyspace IF NOT EXISTS gateway WITH replication = {'class' : 'SimpleStrategy', 'replication_factor' : 1};
  """

  @create_logs_table_query """
    CREATE table IF NOT EXISTS gateway.logs (
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

  defp get_query(:truncate), do: @truncate

  defp get_query(:create_keyspace), do: @create_keyspace_query
  defp get_query(:create_logs_table), do: @create_logs_table_query

<<<<<<< HEAD
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
=======
  defp get_query(:select_by_id), do: @select_by_id_query
  defp get_query(:select_by_idempotency_key), do: @select_by_idempotency_key_query

  defp get_query(:insert_logs), do: @insert_query
>>>>>>> 5328b06fef20cfa7600cd48ad39761d5b9e79f63

  defp get_query(:update_logs), do: @update_query

  defp prepare_query(type) do
    {:ok, query} = type
    |> get_query
    |> Cassandra.prepare
    query
  end

  def execute_query(records, type) do
    records
    |> Enum.map(&Task.async(fn -> Cassandra.execute(prepare_query(type), values: &1) end))
    |> Enum.map(&Task.await/1)
  end
end
