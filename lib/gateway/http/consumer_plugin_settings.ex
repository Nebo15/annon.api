defmodule Gateway.HTTP.ConsumerPluginSettings do
  @moduledoc """
  REST for ConsumerPluginSettings
  Documentation http://docs.osapigateway.apiary.io/#reference/apis
  """
  use Plug.Router
  plug :match
  plug :dispatch
  import Gateway.HTTPHelpers.Response

  import Ecto.Query, only: [from: 2]

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.ConsumerPluginSettings

  get "/:external_id/plugins" do
    ConsumerPluginSettings
    |> Repo.all(external_id: external_id)
    |> render_response(conn)
  end

  get "/:external_id/plugins/:plugin_name" do
    external_id
    |> plugin_by(plugin_name)
    |> Repo.one()
    |> render_response(conn)
  end

  put "/:external_id/plugins/:plugin_name" do
    external_id
    |> plugin_by(plugin_name)
    |> ConsumerPluginSettings.update(conn.body_params)
    |> normalize_ecto_update_resp()
    |> render_response(conn)
  end

  post "/:external_id/plugins" do
    external_id
    |> ConsumerPluginSettings.create(conn.body_params)
    |> render_response(conn, 201)
  end

  delete "/:external_id/plugins/:plugin_name" do
    external_id
    |> plugin_by(plugin_name)
    |> Repo.delete_all()
    |> normalize_ecto_delete_resp()
    |> render_delete_response(conn)
  end

  defp plugin_by(external_id, plugin_name) do
    from c in ConsumerPluginSettings,
      join: p in Plugin, on: c.plugin_id == p.id,
      where: c.external_id == ^external_id,
      where: p.name == ^plugin_name
  end

  defp normalize_ecto_delete_resp({0, _}), do: nil
  defp normalize_ecto_delete_resp({1, _}), do: {:ok, nil}

  defp normalize_ecto_update_resp({0, _}), do: nil
  defp normalize_ecto_update_resp({1, [struct]}), do: struct
  defp normalize_ecto_update_resp({:error, ch}), do: {:error, ch}
end
