defmodule Gateway.DB.Schemas.Consumer do
  @moduledoc """
  Consumer DB entity
  """
  use Gateway.DB, :schema
  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Consumer, as: ConsumerSchema

  @required_consumer_fields [:external_id]

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}
  @primary_key {:external_id, :string, autogenerate: false}
  schema "consumers" do
    field :metadata, :map
    has_many :plugins, Gateway.DB.Schemas.ConsumerPluginSettings, references: :external_id, foreign_key: :external_id

    timestamps()
  end

  def get_one_by(selector) do
    Repo.one from ConsumerSchema,
      where: ^selector,
      limit: 1
  end

  def changeset(consumer, params \\ %{}) do
    consumer
    |> cast(params, @required_consumer_fields ++ [:metadata])
    |> cast_assoc(:plugins)
    |> validate_required(@required_consumer_fields)
    |> unique_constraint(:external_id)
  end

  def create(params) when is_map(params) do
    %ConsumerSchema{}
    |> changeset(params)
    |> Repo.insert()
  end

  def update(consumer_id, params) when is_map(params) do
    try do
      %ConsumerSchema{external_id: consumer_id}
      |> changeset(params)
      |> Repo.update()
    rescue
      Ecto.StaleEntryError -> nil
    end
  end

  def delete(external_id) do
    Repo.delete_all from a in ConsumerSchema,
      where: a.external_id == ^external_id
  end
end
