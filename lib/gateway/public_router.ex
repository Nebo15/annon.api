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
  plug Gateway.Plugins.JWT
  plug Gateway.Plugins.Validator
  plug Gateway.Plugins.Monitoring
  plug :dispatch

  get "/monitoring_test" do
    send_resp(conn, 200, "Temporal route")
  end

  match _ do
    send_resp(conn, 404, "{}")
  end
end
