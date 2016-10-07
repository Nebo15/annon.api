defmodule Gateway.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
end
