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

  match _ do
    send_resp(conn, 404, "{}")
  end
<<<<<<< HEAD
=======

>>>>>>> b2906083ec8e02b83cb5c1b98094f1d77bdd8cc8
end
