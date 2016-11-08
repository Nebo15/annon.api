defmodule Gateway.DB.Schemas.Plugin do
  @moduledoc """
  Schema for Plugins settings.
  """
  use Gateway.DB.Schema

  import Gateway.Changeset.Validator.Settings

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Plugin, as: PluginSchema
  alias Gateway.DB.Schemas.API, as: APISchema

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
    |> validate_inclusion(:name, @valid_plugin_names)
    |> validate_settings()
  end

  def get_one_by(selector) do
    Repo.one from PluginSchema,
      where: ^selector,
      limit: 1
  end

  def get_by(selector, limit) do
    Repo.all from PluginSchema,
      where: ^selector,
      limit: ^limit
  end

  def create(api_id, params) when is_map(params) do
    case Repo.get(APISchema, api_id) do
      %APISchema{} = api ->
        api
        |> Ecto.build_assoc(:plugins)
        |> changeset(params)
        |> Repo.insert()
      _ -> nil
    end
  end

  def update(api_id, name, params) when is_map(params) do
    case get_one_by([api_id: api_id, name: name]) do
      %PluginSchema{} = plugin ->
        plugin
        |> changeset(params)
        |> Repo.update()
      _ -> nil
    end
  end

  def delete(api_id, name) do
    Repo.delete_all from p in PluginSchema,
     where: p.api_id == ^api_id,
     where: p.name == ^name
  end
end
