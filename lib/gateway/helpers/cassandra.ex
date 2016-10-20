defmodule Gateway.Helpers.Cassandra do
  @moduledoc """
  Helper for working with Cassandra
  """
  alias CQEx.Query, as: Q

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

  defp get_statement(:create_keyspace) do
    @create_keyspace_query
  end

  defp get_statement(:create_logs_table) do
    @create_logs_table_query
  end

  defp get_statement(:insert_logs) do
    @insert_query
  end

  defp get_statement(:update_logs) do
    @update_query
  end

  def execute_query(values, type) do
    {:ok, client} = :cqerl.get_client({})

    query = %Q{
      statement: get_statement(type),
      values: values
    }

    client
    |> Q.call!(query)
  end
end
