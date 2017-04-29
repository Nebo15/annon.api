defmodule Annon.Controllers.API.Plugin do
  @moduledoc """
  REST interface that allows to manage Plugins and their settings.

  API plugins allow you to perform certain operations on a request,
  most common of them is Proxy that send incoming requests to a upstream back-end.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/apis/plugins).
  """
  use Annon.Helpers.CommonRouter
  alias Annon.DB.Configs.Repo
  alias Annon.Helpers.Pagination

  alias Annon.DB.Schemas.Plugin, as: PluginSchema

  get "/:api_id/plugins" do
    [api_id: api_id]
    |> PluginSchema.get_by()
    |> Repo.page(Pagination.page_info(conn))
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
