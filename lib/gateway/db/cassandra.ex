defmodule Gateway.DB.Cassandra do
  @moduledoc """
  Cassandra DB module
  """
  use Cassandra
  import Gateway.Helpers.Cassandra
  require Logger

  def start_link, do: Cassandra.Connection.start_link(conf())

  def conf do
    Confex.get_map(:gateway, __MODULE__)
  end
end
