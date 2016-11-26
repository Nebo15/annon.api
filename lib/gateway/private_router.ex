defmodule Gateway.ManagementRouter do
  @moduledoc """
  Router for a [Annons Management API](http://docs.annon.apiary.io/#reference/apis).
  """
  use Plug.Router

  if Confex.get(:gateway, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  use Plug.ErrorHandler

  plug :match

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison

  plug :dispatch

  plug Gateway.ConfigReloader

  forward "/apis", to: Gateway.Controllers.API
  forward "/consumers", to: Gateway.Controllers.Consumer
  forward "/requests", to: Gateway.Controllers.Request

  match _ do
    conn
    |> Gateway.Helpers.Response.send_error(:not_found)
  end

  def handle_errors(conn, error) do
    conn
    |> Gateway.Helpers.Response.send_error(error)
  end
end
