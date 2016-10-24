defmodule Gateway.ConfigReloader do

  @moduledoc """
  Plugin which get all configuration by endpoint
  """

  def init(opts), do: opts

  def call(conn, _) do
    if conn.method in ["POST", "PUT", "DELETE"] do
      Gateway.ConfigGuardian.reload_config()
    end

    # MAYBE also check if resp code is successfull
    # MAYBE rename guardian and reloader

    conn
  end
end
