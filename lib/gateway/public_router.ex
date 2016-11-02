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

  # Monitoring plugins that do not affect on request or response
  plug Gateway.Plugins.Logger
  plug Gateway.Plugins.Monitoring

  # Security plugins that can halt connection immediately
  plug Gateway.Plugins.IPRestriction
  plug Gateway.Plugins.JWT
  plug Gateway.Plugins.ACL

  # Other helper plugins that can halt connection without proxy
  plug Gateway.Plugins.Idempotency
  plug Gateway.Plugins.Validator

  # Proxy
  plug Gateway.Plugins.Proxy

  plug :dispatch

  # TODO: Use EView 404.json view
  match _ do
    send_resp(conn, 404, "{}")
  end
end
