defmodule Gateway.DB.Schemas.Consumer do
  @moduledoc """
  Consumer DB entity
  """
  use Gateway.DB, :schema

  @required_consumer_fields [:external_id]

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}
  @primary_key {:external_id, :string, autogenerate: false}
  schema "consumers" do
    field :metadata, :map
    has_many :plugins, Gateway.DB.Schemas.ConsumerPluginSettings, references: :external_id, foreign_key: :external_id

    timestamps()
  end

  def changeset(consumer, params \\ %{}) do
    consumer
    |> cast(params, @required_consumer_fields ++ [:metadata])
    |> cast_assoc(:plugins)
    |> validate_required(@required_consumer_fields)
    |> unique_constraint(:external_id)
  end

  def create(params) do
    consumer = %Gateway.DB.Schemas.Consumer{}
    changeset = changeset(consumer, params)
    Gateway.DB.Configs.Repo.insert(changeset)
  end

  def update(consumer_id, params) do
    %Gateway.DB.Schemas.Consumer{external_id: consumer_id}
    |> changeset(params)
    |> Gateway.DB.Configs.Repo.update()
  end

  def delete(consumer_id) do
    %Gateway.DB.Schemas.Consumer{external_id: consumer_id}
    |> Gateway.DB.Configs.Repo.delete()
  end
end
