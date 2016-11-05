defmodule Gateway.HTTP.API.Plugins do
  @moduledoc """
  REST module for Plugins.
  """
  use Gateway.Helpers.CommonRouter

  alias Gateway.DB.Schemas.Plugin, as: PluginSchema

  get "/:api_id/plugins" do
    [api_id: api_id]
    |> PluginSchema.get_by(50)
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
