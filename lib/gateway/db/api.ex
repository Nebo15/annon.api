defmodule Gateway.DB.API do
  @moduledoc """
  API DB entity
  """

  use Ecto.Schema

  defimpl Poison.Encoder, for: Gateway.DB.API do
    def encode(%{__struct__: _} = struct, options) do
      map = struct
            |> Map.from_struct
            |> sanitize_map
      Poison.Encoder.Map.encode(map, options)
    end

    defp sanitize_map(map) do
      Map.drop(map, [:__meta__, :__struct__])
    end
  end

  schema "apis" do
    field :name, :string

    embeds_one :request, Request, primary_key: false do
      field :scheme, :string
      field :host, :string
      field :port, :string
      field :path, :string
    end

    timestamps()
  end

  @required_api_fields [:name]
  @required_request_fields [:scheme, :host, :port, :path]

  def changeset(api, params \\ %{}) do
    api
    |> Ecto.Changeset.cast(params, @required_api_fields)
    |> Ecto.Changeset.validate_required(@required_api_fields)
    |> Ecto.Changeset.cast_embed(:request, with: &request_changeset/2)
  end

  def request_changeset(api, params \\ %{}) do
    api
    |> Ecto.Changeset.cast(params, @required_request_fields)
    |> Ecto.Changeset.validate_required(@required_request_fields)
  end

  def create(params) do
    api = %Gateway.DB.API{}
    changeset = changeset(api, params)
    Gateway.DB.Repo.insert(changeset)
  end

  def update(api_id, params) do
    %Gateway.DB.API{ id: String.to_integer(api_id) }
    |> changeset(params)
    |> Gateway.DB.Repo.update()
  end

  def delete(api_id) do
    %Gateway.DB.API{ id: String.to_integer(api_id) }
    |> Gateway.DB.Repo.delete()
  end
end
