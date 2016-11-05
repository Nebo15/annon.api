defmodule Gateway.ConfigReloader do
  @moduledoc """
  Plugin which get all configuration by endpoint
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
