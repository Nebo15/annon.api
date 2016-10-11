defmodule Gateway.HTTPRouter do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
end
