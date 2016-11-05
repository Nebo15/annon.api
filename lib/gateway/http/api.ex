defmodule Gateway.HTTP.API do
  @moduledoc """
  REST for Api
  Documentation http://docs.osapigateway.apiary.io/#reference/apis
  """
  use Gateway.Helpers.CommonRouter
  alias Gateway.DB.Schemas.API, as: APISchema
  alias Gateway.DB.Configs.Repo

  get "/" do
    APISchema
    |> Repo.all
    |> render_collection(conn)
  end

  get "/:api_id" do
    APISchema
    |> Repo.get(api_id)
    |> render_schema(conn)
  end

  put "/:api_id" do
    api_id
    |> APISchema.update(conn.body_params)
    |> render_change(conn)
  end

  post "/" do
    conn.body_params
    |> APISchema.create
    |> render_change(conn, 201)
  end

  delete "/:api_id" do
    api_id
    |> APISchema.delete
    |> render_delete(conn)
  end

  forward "/", to: Gateway.HTTP.API.Plugins
end
