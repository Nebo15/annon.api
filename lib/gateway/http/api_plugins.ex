defmodule Gateway.HTTP.API.Plugins do
  @moduledoc """
  REST module for Plugins.
  """
  use Gateway.Helpers.CommonRouter

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Plugin, as: PluginSchema
  alias Gateway.DB.Schemas.API, as: APISchema

  get "/:api_id/plugins" do
    PluginSchema
    |> Repo.all
    |> render_collection(conn)
  end

  post "/:api_id/plugins" do
    api_id
    |> PluginSchema.create(conn.body_params)
    |> render_change(conn, 201)
  end

  get "/:api_id/plugins/:name" do
    [api_id: api_id, name: name]
    |> PluginSchema.get_one_by()
    |> render_schema(conn)
  end

  put "/:api_id/plugins/:name" do
    api_id
    |> PluginSchema.update(name, conn.body_params)
    |> render_change(conn)
  end

  delete "/:api_id/plugins/:name" do
    api_id
    |> PluginSchema.delete(name)
    |> render_delete(conn)
  end
end
