defmodule Gateway.Router do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match
  plug Gateway.Plugins.Validator
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
end
