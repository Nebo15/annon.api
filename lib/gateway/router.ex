defmodule Gateway.Router do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match

  plug Plug.Parsers, parsers: [:json],
                     pass: ["application/json"],
                     json_decoder: Poison

  plug Gateway.Plugins.Validator
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
end
