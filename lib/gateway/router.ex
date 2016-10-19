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
  plug Gateway.Plugins.APILoader
  plug Gateway.Plugins.Validator
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API

  get "/" do
    send_resp(conn, 200, "{result: ok}")
  end

  forward "/consumers", to: Gateway.HTTP.Consumers

<<<<<<< HEAD
  match "/*_" do
    send_resp(conn, 200, "{result: default}")
  end

=======
  match _ do
    send_resp(conn, 404, "{}")
  end
>>>>>>> 81efb8e67ba9df0b837fb2ab3a4e14fc85c04f12
end
