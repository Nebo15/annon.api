defmodule Annon.ManagementRouter do
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

  plug Annon.ConfigReloader

  forward "/apis", to: Annon.Controllers.API
  forward "/requests", to: Annon.Controllers.Request

  match _ do
    conn
    |> Annon.Helpers.Response.send_error(:not_found)
  end

  def handle_errors(conn, error) do
    conn
    |> Annon.Helpers.Response.send_error(error)
  end
end
