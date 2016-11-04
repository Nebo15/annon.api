defmodule Gateway.HTTP.API do
  @moduledoc """
  REST for Api
  Documentation http://docs.osapigateway.apiary.io/#reference/apis
  """
  use Gateway.Helpers.CommonRouter

  get "/" do
    Gateway.DB.Schemas.API
    |> Gateway.DB.Configs.Repo.all
    |> render_response(conn)
  end

  get "/:api_id" do
    Gateway.DB.Schemas.API
    |> Gateway.DB.Configs.Repo.get(api_id)
    |> render_response(conn)
  end

  put "/:api_id" do
    api_id
    |> Gateway.DB.Schemas.API.update(conn.body_params)
    |> render_response(conn)
  end

  post "/" do
    conn.body_params
    |> Gateway.DB.Schemas.API.create
    |> render_response(conn, 201)
  end

  delete "/:api_id" do
    api_id
    |> Gateway.DB.Schemas.API.delete
    |> render_delete_response(conn)
  end

  forward "/", to: Gateway.HTTP.API.Plugins
end
