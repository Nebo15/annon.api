defmodule Gateway.HTTP.ConsumerPluginSettings do
  use Gateway.Helpers.CommonRouter

  import Ecto.Query, only: [from: 2]

  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Consumer
  alias Gateway.DB.Models.ConsumerPluginSettings

  get "/consumers/:external_id/plugins" do
    ConsumerPluginSettings
    |> Repo.all(external_id)
    |> render_show_response
    |> send_response(conn)
  end

  get "/consumers/:external_id/plugins/:plugin_name" do
    load_plugin(external_id, plugin_name)
    |> render_show_response
    |> send_response(conn)
  end

  put "/consumers/:external_id/plugins/:plugin_name" do
    load_plugin(external_id, plugin_name)
    |> ConsumerPluginSettings.update(conn.body_params)
    |> render_show_response
    |> send_response(conn)
  end

  post "/consumers/:external_id/plugins" do
    external_id
    |> ConsumerPluginSettings.create(conn.body_params)
    |> render_show_response
    |> send_response(conn)
  end

  delete "/consumers/:external_id/plugins/:plugin_name" do
    load_plugin(external_id, plugin_name)
    |> ConsumerPluginSettings.delete
    |> render_show_response
    |> send_response(conn)
  end

  defp load_plugin(external_id, plugin_name) do
    query =
      from p in Plugins,
        join: c in ConsumerPluginSettings, on: c.plugin_id == p.id,
        where: c.external_id == ^external_id,
        where: p.name == ^plugin_name

    Repo.one(query)
  end

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end
end
