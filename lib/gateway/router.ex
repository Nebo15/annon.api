defmodule Gateway.Router do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug Plug.RequestId
  plug Gateway.Logger, 

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass: ["application/json"],
                     json_decoder: Poison
  plug Gateway.Plugins.Getter
  plug Gateway.Plugins.Validator
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API

  get "/" do
    send_resp(conn, 200, "{result: ok}")
  end

  match "/*_" do
    send_resp(conn, 200, "{result: default}")
  end

  forward "/consumers", to: Gateway.HTTP.Consumers

  match _ do
    send_resp(conn, 404, "{}")
  end

end
