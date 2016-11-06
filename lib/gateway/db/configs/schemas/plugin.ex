defmodule Gateway.DB.Schemas.Plugin do
  @moduledoc """
  Model for address
  """
  use Gateway.DB, :schema

  import Gateway.Changeset.SettingsValidator

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema

  @type t :: %Plugin{
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
    belongs_to :api, APISchema

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

  def create(nil, _params), do: nil
  def create(%APISchema{} = api, params) when is_map(params) do
    api
    |> Ecto.build_assoc(:plugins)
    |> Plugin.changeset(params)
    |> Repo.insert
  end

  def update(api_id, name, params) when is_map(params) do
    params = params
    |> Map.put_new("name", name)

    %Plugin{}
    |> Plugin.changeset(params)
    |> update_plugin(api_id, name)
    |> normalize_ecto_update
  end

  defp update_plugin(%Ecto.Changeset{valid?: false} = ch, _api_id, _name), do: {:error, ch}
  defp update_plugin(%Ecto.Changeset{valid?: true, changes: changes}, api_id, name) do
    q = from p in Plugin,
     where: p.api_id == ^api_id,
     where: p.name == ^name

    q
    |> Repo.update_all([set: Map.to_list(changes)], returning: true)
  end

  def delete(api_id, name) do
    q = from p in Plugin,
     where: p.api_id == ^api_id,
     where: p.name == ^name

    q
    |> Repo.delete_all
    |> normalize_ecto_delete
  end
end
