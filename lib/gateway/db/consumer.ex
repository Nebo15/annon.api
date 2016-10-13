defmodule Gateway.DB.Consumer do
  @moduledoc """
  Consumer DB entity
  """

  use Ecto.Schema

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}

  @primary_key {:external_id, :string, autogenerate: false}
  schema "consumers" do
    field :metadata, :map

    timestamps()
  end

  @required_consumer_fields [:external_id]

  def changeset(consumer, params \\ %{}) do
    consumer
    |> Ecto.Changeset.cast(params, @required_consumer_fields ++ [:metadata])
    |> Ecto.Changeset.validate_required(@required_consumer_fields)
  end

  def create(params) do
    consumer = %Gateway.DB.Consumer{}
    changeset = changeset(consumer, params)
    Gateway.DB.Repo.insert(changeset)
  end

  def update(consumer_id, params) do
    %Gateway.DB.Consumer{ external_id: consumer_id }
    |> changeset(params)
    |> Gateway.DB.Repo.update()
  end

  def delete(consumer_id) do
    %Gateway.DB.Consumer{ external_id: consumer_id }
    |> Gateway.DB.Repo.delete()
  end
end
