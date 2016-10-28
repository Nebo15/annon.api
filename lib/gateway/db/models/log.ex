defmodule Gateway.DB.Models.Log do
  @moduledoc """
  Log record DB entity
  """
  alias Gateway.DB.Logger.Repo
  use Gateway.DB, :model
  alias Ecto.Adapters.SQL

  @derive {Poison.Encoder, except: [:__meta__]}

  @primary_key {:id, :string, autogenerate: false}

  schema "logs" do
    field :api, :map
    field :consumer, :map
    field :idempotency_key, :string
    field :ip_address, :string
    field :request, :map
    field :response, :map
    field :latencies, :map
    field :status_code, :integer

    timestamps()
  end


  def changeset(api, params \\ %{}) do
    api
    |> cast(params, [:api, :consumer, :idempotency_key, :ip_address, :request, :response, :latencies, :status_code])
    |> validate_required([:ip_address, :request])
  end

  def create(params \\ %{}) do
    %Gateway.DB.Models.Log{}
    |> cast(params, [:id, :idempotency_key, :ip_address, :request])
    |> Repo.insert
  end

  def update(id, params) do
    %Gateway.DB.Models.Log{id: id}
    |> changeset(params)
    |> Gateway.DB.Repo.update()
  end

  def delete(id) do
    %Gateway.DB.Models.Log{id: id}
    |> Gateway.DB.Repo.delete()
  end

  def get_record_by(selector) do
    Repo.one from Gateway.DB.Models.Log,
    where: ^selector,
    limit: 1
  end

  def get_records do
    query = (from record in Gateway.DB.Models.Log)
    query
    |> Repo.all
  end

  def cleanup do
    SQL.query(Repo, "truncate table logs", [])
  end
end
