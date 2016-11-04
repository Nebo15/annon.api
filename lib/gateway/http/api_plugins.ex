defmodule Gateway.HTTP.API.Plugins do
  @moduledoc """
  REST module for Plugins
  Documentation http://docs.osapigateway.apiary.io/#reference/apis/binded-plugins
  """
  # ToDo: pagination, auth, plugin owner
  use Gateway.Helpers.CommonRouter

  import Ecto.Query, only: [from: 2]

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema

  # list
  get "/:api_id/plugins" do
    query =
      from p in Plugin,
      where: p.api_id == ^api_id,
      limit: 10

    query
    |> Repo.all(api_id: api_id)
    |> render_response(conn)
  end

  # create
  post "/:api_id/plugins" do
    APISchema
    |> Repo.get(api_id)
    |> Plugin.create(conn.body_params)
    |> render_response(conn, 201)
  end

  # get one
  get "/:api_id/plugins/:name" do
    query = from p in Plugin,
            where: p.api_id == ^api_id,
            where: p.name == ^name

    query
    |> Repo.one
    |> render_plugin(conn)
  end

  # update
  put "/:api_id/plugins/:name" do
    api_id
    |> Plugin.update(name, conn.body_params)
    |> render_response(conn)
  end

  delete "/:api_id/plugins/:name" do
    api_id
    |> Plugin.delete(name)
    |> render_delete_response(conn)
  end

  def render_plugin(%Plugin{} = p, conn), do: render_response(p, conn, 200)
  def render_plugin(nil, conn), do: render_response(nil, conn, 404)
end
