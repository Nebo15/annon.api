defmodule Gateway.PublicRouter do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass: ["application/json"],
                     json_decoder: Poison
  plug Plug.RequestId
  plug Gateway.Plugins.APILoader
  plug Gateway.Plugins.IPRestriction
  plug Gateway.Plugins.Logger
  plug Gateway.Plugins.Monitoring
  plug Gateway.Plugins.JWT
  plug Gateway.Plugins.ACL
  plug Gateway.Plugins.Idempotency
  plug Gateway.Plugins.Validator
  plug Gateway.Plugins.Proxy
  plug :dispatch

  # TODO: Use EView 404.json view
  match _ do
    send_resp(conn, 404, "{}")
  end
end
