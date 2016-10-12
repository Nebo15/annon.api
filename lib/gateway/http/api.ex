defmodule Gateway.HTTP.API do
  @moduledoc """
  REST for Api
  Documentation http://docs.osapigateway.apiary.io/#reference/apis
  """
  use Gateway.Helpers.CommonRouter

  get "/" do
    Gateway.DB.API
    |> Gateway.DB.Repo.all
    |> render_show_response
    |> send_response(conn)
  end

  get "/:api_id" do
    Gateway.DB.API
    |> Gateway.DB.Repo.get(api_id)
    |> render_show_response
    |> send_response(conn)
  end

  put "/:api_id" do
    api_id
    |> Gateway.DB.API.update(conn.body_params)
    |> render_show_response
    |> send_response(conn)
  end

  post "/" do
    conn.body_params
    |> Gateway.DB.API.create
    |> render_create_response
    |> send_response(conn)
  end

  delete "/:api_id" do
    api_id
    |> Gateway.DB.API.delete
    |> render_delete_response
    |> send_response(conn)
  end

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end
end
