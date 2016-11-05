defmodule Gateway.DB.Schemas.Plugin do
  @moduledoc """
  Model for address
  """
  use Gateway.DB, :schema

  import Gateway.Changeset.SettingsValidator

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Plugin, as: PluginSchema

  @type t :: %PluginSchema{
    name: atom,
    is_enabled: boolean,
    settings: map
  }

  @derive {Poison.Encoder, except: [:__meta__, :api]}
  @valid_plugin_names ["jwt", "validator", "acl", "proxy", "idempotency", "ip_restriction"]

  schema "plugins" do
    field :name, :string
    field :is_enabled, :boolean, default: false
    field :settings, :map
    belongs_to :api, Gateway.DB.Schemas.API

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :settings, :is_enabled])
    |> assoc_constraint(:api)
    |> unique_constraint(:api_id_name)
    |> validate_required([:name, :settings])
    |> validate_map(:settings)
    |> validate_inclusion(:name, @valid_plugin_names)
    |> validate_settings()
  end

  def create(params) when is_map(params) do
    %PluginSchema{}
    |> changeset(params)
    |> Repo.insert()
  end

  def update(api_id, name, params) when is_map(params) do
    try do
      %PluginSchema{api_id: api_id, name: name}
      |> changeset(params)
      |> Repo.update()
    rescue
      Ecto.StaleEntryError -> nil
    end
  end

  def delete(api_id, name) do
    Repo.delete_all from p in PluginSchema,
     where: p.api_id == ^api_id,
     where: p.name == ^name
  end
end
