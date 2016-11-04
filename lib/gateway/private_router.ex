defmodule Gateway.PrivateRouter do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router
  use Plug.ErrorHandler

  plug :match

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison

  plug :dispatch

  plug Gateway.ConfigReloader

  forward "/apis", to: Gateway.HTTP.API
  forward "/consumers", to: Gateway.HTTP.Consumers
  forward "/requests", to: Gateway.HTTP.Requests

  match _ do
    Gateway.Helpers.Response.send_not_found_error(conn)
  end

  def handle_errors(conn, error) do
    Gateway.Helpers.Response.send_internal_error(conn, error)
  end
end
