defmodule Keepex.Crud.Collection do
  use Plug.Router

  get "/" do
    send_resp(conn, 200, "Getting a new API.")
  end

  post "/" do
    send_resp(conn, 200, "Creating a new API.")
  end
end
