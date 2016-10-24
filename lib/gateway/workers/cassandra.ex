defmodule Gateway.Workers.Cassandra do
  @moduledoc """
  Cassandra worker
  """
<<<<<<< HEAD
  alias Gateway.DB.Cassandra
=======
  use Connection
>>>>>>> 8e929e9b63fbaa634935199c31d2f51e0d9376a6
  import Gateway.Helpers.Cassandra

  def start_link do
    cassandra_config = Confex.get_map(:cassandra, :connection)
<<<<<<< HEAD
    conn = Cassandra.start_link cassandra_config
=======
    conn = Connection.start_link(Cassandra.Connection, cassandra_config, name: Cassandra)
>>>>>>> 8e929e9b63fbaa634935199c31d2f51e0d9376a6
    execute_query([%{}], :create_keyspace)
    execute_query([%{}], :create_logs_table)
    conn
  end
end
