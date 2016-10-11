defmodule Gateway.AMQP.Sample do
  @moduledoc """
  Gateway AMQP sample endpoint
  """
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "A sample thing was added to a queue.")
  end
end
