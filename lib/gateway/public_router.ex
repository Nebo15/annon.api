defmodule Gateway.PublicRouter do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass: ["application/json"],
                     json_decoder: Poison
  plug Gateway.Plugins.APILoader
  plug Gateway.Plugins.Validator
  plug :dispatch

  match _ do
    send_resp(conn, 404, "{}")
  end
end
