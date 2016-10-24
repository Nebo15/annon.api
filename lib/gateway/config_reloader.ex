defmodule Gateway.ConfigReloader do

  @moduledoc """
  Plugin which get all configuration by endpoint
  """

  def init(opts), do: opts

  def call(conn, _) do
    destructive_method? = conn.method in ["POST", "PUT", "DELETE"]
    successful_status? = true # conn.status in [200, 201]

    if destructive_method? && successful_status? do
      Gateway.ConfigGuardian.reload_config()
    end

    # MAYBE also check if resp code is successfull
    # MAYBE rename guardian and reloader

    conn
  end
end
