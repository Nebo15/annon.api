defmodule Gateway.Logger.DB.Models.LogRecord do
  @moduledoc """
  Log record DB entity
  """
  alias Gateway.Logger.DB.Repo
  use Gateway.DB, :model
  alias Ecto.Adapters.SQL

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}

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

  def create(params \\ %{}) do
    %Gateway.Logger.DB.Models.LogRecord{}
    |> cast(params,[:id, :idempotency_key, :ip_address, :request])
    |> Repo.insert
  end

  def update(params) do
    %Gateway.Logger.DB.Models.LogRecord{id: Map.get(params, :id)}
    |> cast(params, [:id, :api, :consumer, :response, :latencies, :status_code])
    |> Repo.update
  end

  def delete(params) do
    %Gateway.Logger.DB.Models.LogRecord{id: Map.get(params, :id)}
    |> Repo.delete
  end

  def get_record_by(selector) do
    Repo.one from Gateway.Logger.DB.Models.LogRecord,
    where: ^selector,
    limit: 1
  end

  def get_records do
    Repo.all(%Gateway.Logger.DB.Models.LogRecord{})
  end

  def cleanup do
    SQL.query(Repo,"truncate table logs", [])
  end
end
