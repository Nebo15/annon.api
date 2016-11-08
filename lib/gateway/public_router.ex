defmodule Gateway.PublicRouter do
  @moduledoc """
  Router for a Annons public API.

  It has all available plugins assigned (in a specific order),
  but witch of them should process request will be resolved in run-time.
  """
  use Plug.Router
  use Plug.ErrorHandler

  plug :match

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison

  plug Gateway.Plugins.APILoader

  plug Gateway.Plugins.Idempotency # TODO: set plug after logger plug (and after acl/iprestiction, in others section)

  # Monitoring plugins that do not affect on request or response
  plug Gateway.Plugins.Logger
  plug Gateway.Plugins.Monitoring

  # Security plugins that can halt connection immediately
  plug Gateway.Plugins.IPRestriction
  plug Gateway.Plugins.JWT
  plug Gateway.Plugins.ACL

  # Other helper plugins that can halt connection without proxy
  plug Gateway.Plugins.Validator

  # Proxy
  plug Gateway.Plugins.Proxy

  plug :dispatch

  match _ do
    conn
    |> Gateway.Helpers.Response.send_error(:not_found)
  end

  def handle_errors(conn, error) do
    conn
    |> Gateway.Helpers.Response.send_error(error)
  end
end
