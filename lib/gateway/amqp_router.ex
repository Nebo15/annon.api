defmodule Gateway.AMQPRouter do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match
  plug :dispatch

  get "/*path" do
    send_resp(conn, 200, Poison.encode!(%{ response: "To AMQP client." }))
  end
end
