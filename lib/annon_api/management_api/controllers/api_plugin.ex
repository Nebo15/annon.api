defmodule Annon.ManagementAPI.Controllers.APIPlugin do
  @moduledoc """
  REST interface that allows to manage Plugins and their settings.

  API plugins allow you to perform certain operations on a request,
  most common of them is Proxy that send incoming requests to a upstream back-end.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/apis/plugins).
  """
  use Annon.ManagementAPI.ControllersRouter
  alias Annon.Configuration.API, as: ConfigurationAPI
  alias Annon.Configuration.Plugin, as: ConfigurationPlugin
  alias Annon.Configuration.Schemas.Plugin, as: PluginSchema
  alias Annon.Configuration.Schemas.API, as: APISchema

  get "/:api_id/plugins" do
    api_id
    |> ConfigurationPlugin.list_plugins()
    |> render_collection(conn)
  end

  get "/:api_id/plugins/:name" do
    api_id
    |> ConfigurationPlugin.get_plugin(name)
    |> render_one(conn)
  end

  put "/:api_id/plugins/:name" do
    # Name from URI path has bigger priority since we are accessing resource
    attrs = Map.put(conn.body_params, "name", name)

    case ConfigurationPlugin.get_plugin(api_id, name) do
      {:ok, %PluginSchema{} = plugin} ->
        plugin
        |> ConfigurationPlugin.update_plugin(attrs)
        |> render_one(conn, 200)

      {:error, :not_found} ->
        with {:ok, %APISchema{} = api} <- ConfigurationAPI.get_api(api_id) do
          api
          |> ConfigurationPlugin.create_plugin(attrs)
          |> render_one(conn, 201)
        else
          {:error, :not_found} = err ->
            render_one(err, conn)
        end
    end
  end

  delete "/:api_id/plugins/:name" do
    case ConfigurationPlugin.get_plugin(api_id, name) do
      {:ok, plugin} ->
        ConfigurationPlugin.delete_plugin(plugin)
        render_delete(conn)
      {:error, :not_found} ->
        render_delete(conn)
    end
  end
end
