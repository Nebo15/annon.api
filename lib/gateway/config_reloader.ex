defmodule Gateway.ConfigReloader do
  @moduledoc """
  This plugin
  [invalidates Annons cache](http://docs.annon.apiary.io/#introduction/general-features/caching-and-perfomance)
  whenever there was change triggered by a management API.
  """
  alias Gateway.AutoClustering

  @destructive_methods ["POST", "PUT", "DELETE"]
  @successful_statuses [200, 201]

  def init(opts), do: opts

  def call(%Plug.Conn{method: method, status: status} = conn, _opts)
      when method in @destructive_methods and status in @successful_statuses do
    AutoClustering.reload_config()

    conn
  end
  def call(conn, _opts), do: conn
end
