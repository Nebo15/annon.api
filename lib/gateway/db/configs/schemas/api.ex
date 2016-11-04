defmodule Gateway.DB.Schemas.API do
  @moduledoc """
  API DB entity
  """
  use Gateway.DB, :schema
  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.API, as: APIModel

  @required_api_fields [:name]
  @required_request_fields [:scheme, :host, :port, :path, :method]

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}
  schema "apis" do
    field :name, :string

    embeds_one :request, Request, primary_key: false do
      field :scheme, :string
      field :host, :string
      field :port, :integer
      field :path, :string
      field :method, :string
    end

    has_many :plugins, Gateway.DB.Schemas.Plugin

    timestamps()
  end

  def changeset(api, params \\ %{}) do
    api
    |> cast(params, @required_api_fields)
    |> validate_required(@required_api_fields)
    |> cast_assoc(:plugins)
    |> cast_embed(:request, with: &request_changeset/2)
  end

  def request_changeset(api, params \\ %{}) do
    api
    |> cast(params, @required_request_fields)
    |> validate_required(@required_request_fields)
  end

  def create(params) do
    %APIModel{}
    |> changeset(params)
    |> Gateway.DB.Configs.Repo.insert
  end

  def update(api_id, params) do
    try do
      %Gateway.DB.Schemas.API{id: String.to_integer(api_id)}
      |> changeset(params)
      |> Gateway.DB.Configs.Repo.update()
    rescue
      Ecto.StaleEntryError -> nil
    end
  end

  def delete(api_id) do
    q = from a in APIModel,
      where: a.id == ^api_id

    q
    |> Repo.delete_all
    |> normalize_ecto_delete
  end
end
