defmodule Gateway.ConfigReloader do

  @moduledoc """
  Plugin which get all configuration by endpoint
  """

  def init(opts), do: opts

  def call(conn, _) do
    destructive_method? = conn.method in ["POST", "PUT", "DELETE"]
    successful_status? = conn.status in [200, 201]

    if destructive_method? && successful_status? do
      Gateway.AutoClustering.reload_config()
    end

    conn
  end
end
