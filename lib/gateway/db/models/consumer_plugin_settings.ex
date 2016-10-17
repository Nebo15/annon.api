defmodule Gateway.DB.Models.ConsumerPluginSettings do
  @moduledoc """
  Model for address
  """
  use Gateway.DB, :model

  alias Gateway.DB.Repo
  alias Gateway.DB.Consumer
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.ConsumerPluginSettings

  @derive {Poison.Encoder, except: [:__meta__, :api]}

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

  def delete(struct) do
    struct
    |> Repo.delete
  end
end
