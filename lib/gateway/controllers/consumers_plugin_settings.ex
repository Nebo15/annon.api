defmodule Gateway.Controllers.Consumers.PluginSettings do
  @moduledoc """
  REST interface that allows to manage overrides for Consumer plugin settings.

  By overriding them you can define personal rules for processing hes requests.

  You can find full description in
  [REST API documentation](http://docs.annon.apiary.io/#reference/consumers/consumer-settings-overrides-for-plugins).
  """
  use Gateway.Helpers.CommonRouter

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.ConsumerPluginSettings, as: ConsumerPluginSettingsSchema

  get "/:external_id/plugins" do
    ConsumerPluginSettingsSchema
    |> Repo.all(external_id: external_id)
    |> render_collection(conn)
  end

  get "/:external_id/plugins/:plugin_name" do
    external_id
    |> ConsumerPluginSettingsSchema.get_by_name(plugin_name)
    |> render_schema(conn)
  end

  put "/:external_id/plugins/:plugin_name" do
    external_id
    |> ConsumerPluginSettingsSchema.update(plugin_name, conn.body_params)
    |> render_change(conn)
  end

  post "/:external_id/plugins" do
    external_id
    |> ConsumerPluginSettingsSchema.create(conn.body_params)
    |> render_change(conn, 201)
  end

  delete "/:external_id/plugins/:plugin_name" do
    external_id
    |> ConsumerPluginSettingsSchema.delete(plugin_name)
    |> render_delete(conn)
  end
end
