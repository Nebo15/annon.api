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
  get "/:api_id/plugins/:id" do
    query = from p in Plugin,
            where: p.api_id == ^api_id,
            where: p.id == ^id,
            limit: 10

    query
    |> Repo.one
    |> render_plugin
    |> send_response(conn)
  end

  # create
  post "/:api_id/plugins/" do
    api_id
    |> get_api
    |> create_plugin(conn.body_params)
    |> render_create_response
    |> send_response(conn)
  end

  # update
  put "/:api_id/plugins/:name" do
    api_id
    |> update_plugin(name, conn.body_params)
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

  defp get_api(api_id) do
    APIModel
    |> Repo.get(api_id)
  end

  defp create_plugin(nil, _params), do: nil
  defp create_plugin(%APIModel{} = api, params) when is_map(params) do
    api
    |> Ecto.build_assoc(:plugins)
    |> Plugin.changeset(params)
    |> Repo.insert
  end

  defp update_plugin(api_id, name, params) when is_map(params) do
    a =
    %Plugin{}
    |> Plugin.changeset(params)
    |> update_plugin(api_id, name)
    IO.inspect a
    a
  end
  defp update_plugin(%Ecto.Changeset{valid?: true, changes: changes}, api_id, name) do

    changes = Map.to_list(changes)
    query = from(p in Plugin, where: p.api_id == ^api_id, where: p.name == ^name,
                 update: [set: ^changes])
    IO.inspect query
    a = query
    Repo.update_all([], returning: true)
    IO.inspect a
    a
  end
  defp update_plugin(%Ecto.Changeset{valid?: false} = ch), do: {:error, ch}

  def render_plugin(%Plugin{} = p), do: render_show_response(p)
  def render_plugin(nil), do: render_not_found_response("Plugin not found")

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end
end
