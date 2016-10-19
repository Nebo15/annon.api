defmodule Gateway.Router do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass: ["application/json"],
                     json_decoder: Poison
  plug Gateway.Plugins.APILoader
  plug Gateway.Plugins.JWT
  plug Gateway.Plugins.Validator
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
  forward "/consumers", to: Gateway.HTTP.Consumers

  match _ do
    send_resp(conn, 404, "{}")
  end
end
