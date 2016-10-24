defmodule Gateway.Workers.Cassandra do
  @moduledoc """
  Cassandra worker
  """
  alias Gateway.DB.Cassandra
  import Gateway.Helpers.Cassandra

  def start_link do
    cassandra_config = Confex.get_map(:cassandra, :connection)
    conn = Cassandra.start_link(cassandra_config)
    execute_query([%{}], :create_keyspace)
    execute_query([%{}], :create_logs_table)
    conn
  end
end
