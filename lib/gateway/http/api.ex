defmodule Gateway.HTTP.API do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Getting a new API.")
  end

  post "/" do
    send_resp(conn, 200, "Creating a new API.")
  end

  forward "/", to: Gateway.HTTP.API.Plugins
end
