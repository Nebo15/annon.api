defmodule Gateway.HTTP.API.Plugins do
  @moduledoc """
  REST module for Plugins
  Documentation http://docs.osapigateway.apiary.io/#reference/apis/binded-plugins
  """
  # ToDo: pagination, auth, plugin owner
  use Gateway.Helpers.CommonRouter

  import Ecto.Query, only: [from: 2]

  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API

  # list
  get "/:api_id/plugins" do
    Plugin
    |> Repo.all(api_id: api_id)
    |> render_show_response
    |> send_response(conn)
  end

  # create
  post "/:api_id/plugins" do
    api_id
    |> Plugin.create(conn.body_params)
    |> render_create_response
    |> send_response(conn)
  end

  # get one
  get "/:api_id/plugins/:name" do
    api_id
    |> load_plugin(name)
    |> render_plugin
    |> send_response(conn)
  end

  # update
  put "/:api_id/plugins/:name" do
    api_id
    |> load_plugin(name)
    |> Plugin.update(conn.body_params)
    |> render_show_response
    |> send_response(conn)
  end

  delete "/:api_id/plugins/:name" do
    api_id
    |> load_plugin(name)
    |> Plugin.delete()
    |> render_delete_response
    |> send_response(conn)
  end

  def render_plugin(%Plugin{} = p), do: render_show_response(p)
  def render_plugin(nil), do: render_not_found_response("Plugin not found")

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end

  defp load_plugin(api_id, plugin_name) do
    query =
      from p in Plugin,
        join: a in API, on: a.id == p.api_id,
        where: a.id == ^api_id,
        where: p.name == ^plugin_name

    Repo.one(query)
  end
end
