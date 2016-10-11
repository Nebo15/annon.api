defmodule Gateway.Router do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router
  
  plug Gateway.Monitoring
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison

  plug :match
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
end
