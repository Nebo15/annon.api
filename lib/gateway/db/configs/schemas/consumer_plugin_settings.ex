defmodule Gateway.DB.Schemas.ConsumerPluginSettings do
  @moduledoc """
  Schema for Consumer's overrides for plugin settings.
  """
  use Gateway.DB.Schema

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Plugin, as: PluginSchema
  alias Gateway.DB.Schemas.ConsumerPluginSettings, as: ConsumerPluginSettingsSchema

  @derive {Poison.Encoder, except: [:__meta__, :consumer, :plugin]}
  schema "consumer_plugin_settings" do
    field :settings, :map
    field :is_enabled, :boolean
    belongs_to :consumer, Gateway.DB.Schemas.Consumer,
      references: :external_id, foreign_key: :external_id, type: :string
    belongs_to :plugin, PluginSchema

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:plugin_id, :external_id, :settings, :is_enabled])
    |> assoc_constraint(:consumer)
    |> assoc_constraint(:plugin)
    |> unique_constraint(:plugin, name: :external_id_plugin_id_index)
  end

  def get_by_name(external_id, plugin_name) do
    Repo.one from c in ConsumerPluginSettingsSchema,
      join: p in PluginSchema, on: c.plugin_id == p.id,
      where: c.external_id == ^external_id,
      where: p.name == ^plugin_name
  end

  def create(external_id, params) when is_map(params) do
    %ConsumerPluginSettingsSchema{external_id: external_id}
    |> changeset(params)
    |> Repo.insert()
  end

  def update(external_id, name, params) when is_map(params) do
    case get_by_name(external_id, name) do
      %ConsumerPluginSettingsSchema{} = schema ->
        params = params
        |> Map.put_new("name", name)

        schema
        |> changeset(params)
        |> Repo.update()
      _ -> nil
    end
  end

  def delete(external_id, plugin_name) do
    Repo.delete_all from c in ConsumerPluginSettingsSchema,
      join: p in PluginSchema, on: c.plugin_id == p.id,
      where: c.external_id == ^external_id,
      where: p.name == ^plugin_name
  end
end
