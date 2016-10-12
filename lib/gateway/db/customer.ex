defmodule Gateway.DB.Consumer do
  @moduledoc """
  Consumer DB entity
  """

  use Ecto.Schema

  defimpl Poison.Encoder, for: Gateway.DB.Consumer do
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

  schema "consumers" do
    field :external_id, :string
    field :metadata, :map

    timestamps()
  end

  @required_consumer_fields [:name]

  def changeset(api, params \\ %{}) do
    api
    |> Ecto.Changeset.cast(params, @required_consumer_fields)
    |> Ecto.Changeset.validate_required(@required_consumer_fields)
  end

  def create(params) do
    api = %Gateway.DB.Consumer{}
    changeset = changeset(api, params)
    Gateway.DB.Repo.insert(changeset)
  end

  def update(api_id, params) do
    %Gateway.DB.Consumer{ id: String.to_integer(api_id) }
    |> changeset(params)
    |> Gateway.DB.Repo.update()
  end

  def delete(api_id) do
    %Gateway.DB.Consumer{ id: String.to_integer(api_id) }
    |> Gateway.DB.Repo.delete()
  end
end
