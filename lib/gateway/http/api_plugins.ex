defmodule Gateway.HTTP.API.Plugins do
  @moduledoc """
  REST module for Plugins
  Documentation http://docs.osapigateway.apiary.io/#reference/apis/binded-plugins
  """
  # ToDo: pagination, auth, plugin owner
  use Gateway.Helpers.CommonRouter

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  plug :match
  plug :dispatch

  # list
  get "/:api_id/plugins" do
    query = from p in Plugin,
            where: p.api_id == ^api_id,
            limit: 10

    query
    |> Repo.all(api_id: api_id)
    |> render_show_response
    |> send_response(conn)
  end

  # get one
  get "/:api_id/plugins/:name" do
    query = from p in Plugin,
            where: p.api_id == ^api_id,
            where: p.name == ^name

    query
    |> Repo.one
    |> render_plugin
    |> send_response(conn)
  end

  # create
  post "/:api_id/plugins/" do
    APIModel
    |> Repo.get(api_id)
    |> Plugin.create(conn.body_params)
    |> render_create_response
    |> send_response(conn)
  end

  # update
  put "/:api_id/plugins/:name" do
    api_id
    |> Plugin.update(name, conn.body_params)
    |> render_show_response
    |> send_response(conn)
  end

  delete "/:api_id/plugins/:name" do
    query = from p in Plugin,
            where: p.api_id == ^api_id,
            where: p.name == ^name
    query
    |> Repo.delete_all
    |> render_delete_response
    |> send_response(conn)
  end

  defp normalize_ecto_update_resp({0, _}), do: nil
  defp normalize_ecto_update_resp({1, [struct]}), do: struct

  def render_plugin(%Plugin{} = p), do: render_show_response(p)
  def render_plugin(nil), do: render_not_found_response("Plugin not found")

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end
end
