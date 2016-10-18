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
    IO.inspect api
#    put_private(conn, :api_config, conn |> get_config)
    conn
  end

  def call(conn, _) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(501, err_msg())
    |> halt
  end

  defp err_msg do
    Poison.encode!(%{
      meta: %{
        code: 501,
        error: "plug call error"
      }
    })
  end

#  plug_call
end
