defmodule Gateway.HTTP.API do
  @moduledoc """
  REST for Api
  Documentation http://docs.osapigateway.apiary.io/#reference/apis
  """
  use Gateway.Helpers.CommonRouter

  get "/" do
    Gateway.DB.Models.API
    |> Gateway.DB.Repo.all
    |> render_response(conn)
  end

  get "/:api_id" do
    Gateway.DB.Models.API
    |> Gateway.DB.Repo.get(api_id)
    |> render_response(conn)
  end

  put "/:api_id" do
    api_id
    |> Gateway.DB.Models.API.update(conn.body_params)
    |> render_response(conn)
  end

  post "/" do
    conn.body_params
    |> Gateway.DB.Models.API.create
    |> render_response(conn, 201)
  end

  delete "/:api_id" do
    api_id
    |> Gateway.DB.Models.API.delete
    |> render_delete_response(conn)
  end

  forward "/", to: Gateway.HTTP.API.Plugins
end
