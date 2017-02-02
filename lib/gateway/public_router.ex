defmodule Gateway.PublicRouter do
  @moduledoc """
  Router for a Annons public API.

  It has all available plugins assigned (in a specific order),
  but witch of them should process request will be resolved in run-time.
  """
  use Plug.Router

  if Confex.get(:gateway, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  use Plug.ErrorHandler

  plug :match

  # Plugin that traces request start time
  plug Gateway.Plugins.ClientLatency

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:multipart, :json],
                     pass: ["*/*"],
                     json_decoder: Poison,
                     length: 4_294_967_296,
                     read_length: 2_000_000,
                     read_timeout: 108_000

  plug Gateway.Plugins.APILoader

  plug Gateway.Plugins.CORS

  plug Gateway.Plugins.Idempotency # TODO: set plug after logger plug (and after acl/iprestiction, in others section)

  # Monitoring plugins that do not affect on request or response
  plug Gateway.Plugins.Logger
  plug Gateway.Plugins.Monitoring

  # Security plugins that can halt connection immediately
  plug Gateway.Plugins.IPRestriction
  plug Gateway.Plugins.UARestriction
  plug Gateway.Plugins.JWT
  plug Gateway.Plugins.Scopes
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

  def handle_errors(%Plug.Conn{halted: false} = conn, error) do
    conn
    |> Gateway.Helpers.Response.send_error(error)
  end
end
