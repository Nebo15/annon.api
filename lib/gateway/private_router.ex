defmodule Gateway.PrivateRouter do
  @moduledoc """
  Gateway HTTP Router
  """

  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
                     pass: ["application/json"],
                     json_decoder: Poison

  plug :dispatch
  plug Gateway.ConfigReloader

  forward "/apis", to: Gateway.HTTP.API

  # TODO: WTF is this?
  get "/" do
    send_resp(conn, 200, "{result: ok}")
  end

  forward "/consumers", to: Gateway.HTTP.Consumers

  forward "/requests", to: Gateway.HTTP.Requests
end
