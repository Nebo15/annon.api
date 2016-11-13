defmodule Gateway.DB.Schemas.API do
  @moduledoc """
  Schema for API's entity.
  """
  use Gateway.DB.Schema
  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.API, as: APISchema

  @required_api_fields [:name]
  @required_request_fields [:scheme, :host, :port, :path, :method]

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}
  schema "apis" do
    field :name, :string

    embeds_one :request, Request, primary_key: false, on_replace: :update do
      field :scheme, :string
      field :host, :string
      field :port, :integer
      field :path, :string
      field :method, {:array, :string}
    end

    has_many :plugins, Gateway.DB.Schemas.Plugin

    timestamps()
  end

  def get_one_by(selector) do
    Repo.one from APISchema,
      where: ^selector,
      limit: 1,
      preload: [:plugins]
  end

  def changeset(api, params \\ %{}) do
    api
    |> cast(params, @required_api_fields)
    |> validate_required(@required_api_fields)
    |> cast_embed(:request, with: &request_changeset/2)
    |> cast_assoc(:plugins)
    |> unique_constraint(:name, name: :apis_name_index)
    |> unique_constraint(:request, name: :api_unique_request_index)
  end

  def request_changeset(api, params \\ %{}) do
    api
    |> cast(params, @required_request_fields)
    |> validate_required(@required_request_fields)
  end

  def create(params) when is_map(params) do
    %APISchema{}
    |> changeset(params)
    |> Repo.insert()
  end

  def update(api_id, params) when is_map(params) do
    case get_one_by([id: api_id]) do
      %APISchema{} = api ->
        api
        |> changeset(params)
        |> Repo.update()
      _ -> nil
    end
  end

  def delete(api_id) do
    Repo.delete_all from a in APISchema,
      where: a.id == ^api_id
  end
end
