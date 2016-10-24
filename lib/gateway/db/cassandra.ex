defmodule Gateway.DB.Cassandra do
  @moduledoc """
  Cassandra DB module
  """
  use Cassandra
  import Gateway.Helpers.Cassandra
  require Logger

  def start_link do
    cassandra_config = conf()
    Logger.info("Starting Cassandra connection: #{inspect cassandra_config}")
    {:ok, pid} = start_link(cassandra_config)
    execute_query([%{}], :create_keyspace)
    execute_query([%{}], :create_logs_table)
    {:ok, pid}
  end

  def conf do
    Confex.get_map(:gateway, __MODULE__)
  end
end
