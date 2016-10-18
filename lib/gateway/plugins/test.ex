defmodule Gateway.Plugins.Test do

  @moduledoc """
  Plugin which get all configuration by endpoint
  """

  import Plug.Conn
  import Ecto.Query
  import Gateway.Plugins.Helper
  alias Gateway.DB.Models.API, as: APIModel

  def init(opts), do: opts

  def call(%Plug.Conn{private: %{api_config: %APIModel{} = api}} = conn, opt) do
    IO.inspect conn
#    put_private(conn, :api_config, conn |> get_config)
    conn
  end

  def call(conn, _) do
    conn
    |> halt
  end

#  plug_call
end
