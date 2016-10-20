defmodule Gateway.Workers.Cassandra do
  @moduledoc """
  Cassandra worker
  """
  import Gateway.Helpers.Cassandra

  def start_link do
    {pid, _reference} = CQEx.Client.new!
    execute_query([], :create_keyspace)
    execute_query([], :create_logs_table)
    {:ok, pid}
  end
end
