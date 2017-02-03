defmodule Gateway.PrivateRouter do
  @moduledoc """
  Router for a private APIs inside you clusters.
  """
  use Plug.Router

  plug :match

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison

  plug :dispatch

  forward "/", to: Gateway.PublicRouter
end
