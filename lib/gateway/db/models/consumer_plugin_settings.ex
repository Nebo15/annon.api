defmodule Gateway.DB.Models.ConsumerPluginSettings do
  @moduledoc """
  Model for address
  """
  use Gateway.DB, :model

  alias Gateway.DB.Repo
  alias Gateway.DB.Consumer
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.ConsumerPluginSettings

  @derive {Poison.Encoder, except: [:__meta__, :consumer, :plugin]}

  schema "consumer_plugin_settings" do
    field :settings, :map
    belongs_to :consumer, Consumer, references: :external_id, foreign_key: :external_id, type: :string
    belongs_to :plugin, Plugin

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:plugin_id, :external_id, :settings])
    |> validate_map(:settings)
    |> assoc_constraint(:consumer)
    |> assoc_constraint(:plugin)
    |> unique_constraint(:external_id_plugin_id)
  end

  def create(external_id, params) do
    %ConsumerPluginSettings{ external_id: external_id }
    |> changeset(params)
    |> Repo.insert
  end

  def update(struct, params) do
    struct
    |> changeset(params)
    |> Repo.update
  end

  def delete(external_id, plugin_name) do
    by_plugin_and_consumer(external_id, plugin_name)
    |> Repo.delete_all
    |> normalize_ecto_delete_resp
  end

  def by_plugin_and_consumer(external_id, plugin_name) do
    query =
      from c in ConsumerPluginSettings,
        join: p in Plugin, on: c.plugin_id == p.id,
        where: c.external_id == ^external_id,
        where: p.name == ^plugin_name
  end

  defp normalize_ecto_delete_resp({0, _}), do: nil
  defp normalize_ecto_delete_resp({1, _}), do: {:ok, nil}
end
