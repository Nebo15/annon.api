defmodule Gateway.AMQPRouter do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/queue", to: Gateway.AMQP.Sample
end
