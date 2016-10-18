defmodule Gateway.Router do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match
  plug Gateway.Plugins.Getter
  plug Gateway.Plugins.JWT
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
  forward "/consumers", to: Gateway.HTTP.Consumers
end
