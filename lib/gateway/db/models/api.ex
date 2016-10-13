defmodule Gateway.DB.Models.API do
  @moduledoc """
  API DB entity
  """

  use Gateway.DB, :model

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}

  schema "apis" do
    field :name, :string

    embeds_one :request, Request, primary_key: false do
      field :scheme, :string
      field :host, :string
      field :port, :integer
      field :path, :string
    end

    has_many :plugins, Gateway.DB.Models.Plugin

    timestamps()
  end

  @required_api_fields [:name]
  @required_request_fields [:scheme, :host, :port, :path]

  def changeset(api, params \\ %{}) do
    api
    |> cast(params, @required_api_fields)
    |> validate_required(@required_api_fields)
    |> cast_assoc(:plugins) |> cast_embed(:request, with: &request_changeset/2)
  end

  def request_changeset(api, params \\ %{}) do
    api
    |> cast(params, @required_request_fields)
    |> validate_required(@required_request_fields)
  end

  def create(params) do
    %Gateway.DB.Models.API{}
    |> changeset(params)
    |> Gateway.DB.Repo.insert
  end

  def update(api_id, params) do
    %Gateway.DB.Models.API{id: String.to_integer(api_id)}
    |> changeset(params)
    |> Gateway.DB.Repo.update()
  end

  def delete(api_id) do
    %Gateway.DB.Models.API{id: String.to_integer(api_id)}
    |> Gateway.DB.Repo.delete()
  end
end
