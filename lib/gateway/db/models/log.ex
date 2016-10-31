defmodule Gateway.DB.Models.Log do
  @moduledoc """
  Log record DB entity
  """
  use Gateway.DB, :model
  alias Gateway.DB.Logger.Repo

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

  def changeset_response(api, params \\ %{}) do
    api
    |> cast(params, [:api, :consumer, :idempotency_key, :ip_address, :request, :response, :latencies, :status_code])
    |> validate_required([:api, :consumer, :latencies, :response, :status_code])
  end

  def create(params \\ %{}) do
    %Gateway.DB.Models.Log{}
    |> cast(params, [:id, :idempotency_key, :ip_address, :request])
    |> Repo.insert
  end

  def put_response(id, params) do
    %Gateway.DB.Models.Log{id: id}
    |> changeset_response(params)
    |> Repo.update()
  end

  def delete(id) do
    %Gateway.DB.Models.Log{id: id}
    |> Repo.delete()
  end

  def get_record_by(selector) do
    Repo.one from Gateway.DB.Models.Log,
      where: ^selector,
      limit: 1
  end

  def get_records do
    Repo.all from record in Gateway.DB.Models.Log
  end

  def get_records(limit) when is_integer(limit) do
    Repo.all from record in Gateway.DB.Models.Log,
      limit: ^limit
  end
end
