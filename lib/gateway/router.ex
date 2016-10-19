defmodule Gateway.Router do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router
<<<<<<< HEAD
  
=======

>>>>>>> origin/OSL-381
  plug Gateway.Monitoring
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison

  plug :match
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
end
