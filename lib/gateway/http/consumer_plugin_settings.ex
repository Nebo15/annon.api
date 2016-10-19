defmodule Gateway.HTTP.ConsumerPluginSettings do
  @moduledoc """
  REST for ConsumerPluginSettings
  Documentation http://docs.osapigateway.apiary.io/#reference/apis
  """
  use Gateway.Helpers.CommonRouter

  import Ecto.Query, only: [from: 2]

  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.ConsumerPluginSettings

  get "/consumers/:external_id/plugins" do
    ConsumerPluginSettings
    |> Repo.all(external_id: external_id)
    |> render_show_response
    |> send_response(conn)
  end

  get "/consumers/:external_id/plugins/:plugin_name" do
    external_id
    |> plugin_by(plugin_name)
    |> Repo.one()
    |> render_show_response
    |> send_response(conn)
  end

  put "/consumers/:external_id/plugins/:plugin_name" do
    external_id
    |> plugin_by(plugin_name)
    |> ConsumerPluginSettings.update(conn.body_params)
    |> normalize_ecto_update_resp
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
    external_id
    |> plugin_by(plugin_name)
    |> Repo.delete_all
    |> normalize_ecto_delete_resp
    |> render_delete_response
    |> send_response(conn)
  end

  defp plugin_by(external_id, plugin_name) do
    from c in ConsumerPluginSettings,
      join: p in Plugin, on: c.plugin_id == p.id,
      where: c.external_id == ^external_id,
      where: p.name == ^plugin_name
  end

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end

  defp normalize_ecto_delete_resp({0, _}), do: nil
  defp normalize_ecto_delete_resp({1, _}), do: {:ok, nil}

  defp normalize_ecto_update_resp({0, _}), do: nil
  defp normalize_ecto_update_resp({1, [struct]}), do: struct
  defp normalize_ecto_update_resp({:error, ch}), do: {:error, ch}
end
