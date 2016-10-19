defmodule Gateway.Workers.Cassandra do
  @moduledoc """
  Cassandra worker
  """
  use Connection
  import Gateway.Helpers.Cassandra

  def start_link do
    cassandra_config = Confex.get_map(:cassandra, :connection)
    Connection.start_link(Cassandra.Connection, cassandra_config, name: Cassandra)
    execute_query([], :create_keyspace)    
  end
end
