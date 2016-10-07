defmodule Gateway.HTTP.API.Plugins do
  @moduledoc """
  REST module for Plugins
  Documentation http://docs.osapigateway.apiary.io/#reference/apis/binded-plugins
  """
  use Plug.Router

  plug :match
  plug :dispatch

  # list
  get "/:id/plugins" do
    send_resp(conn, 200, "Getting plugins.")
  end

  # get one
  get "/:id/plugins/:name" do
    send_resp(conn, 200, "Getting plugin.")
  end

  # create
  post "/:id/plugins/" do
    send_resp(conn, 200, "Creating a new API.")
  end

  # update
  put "/:id/plugins/:name" do
    send_resp(conn, 200, "Creating a new API.")
  end

  delete "/:id/plugins/:name" do
    send_resp(conn, 200, "Creating a new API.")
  end
end
