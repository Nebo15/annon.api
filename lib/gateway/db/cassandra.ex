defmodule Gateway.DB.Cassandra do
  @moduledoc """
  Cassandra DB module
  """
  use Cassandra
  import Gateway.Helpers.Cassandra
  require Logger

  def start_link do
    {:ok, pid} = Cassandra.Connection.start_link(conf())

#    Gateway.Helpers.Cassandra.execute_query([%{}], :create_keyspace)
#    Gateway.Helpers.Cassandra.execute_query([%{}], :create_logs_table)
    {:ok, pid}
  end

  def conf do
    Confex.get_map(:gateway, __MODULE__)
  end
end
