defmodule Gateway.Logger.DB.Models.LogRecord do
  @moduledoc """
  Log record DB entity
  """

  use Gateway.DB, :model

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}

  @primary_key {:_id, :id, autogenerate: true}

  schema "logs" do
    field :id, :integer
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
    |> Gateway.Logger.DB.Repo.insert
  end

  def update(record_id, params) do
    %Gateway.Logger.DB.Models.LogRecord{id: record_id}
    |> cast(params, [:api, :consumer, :response, :latencies, :status_code])
    |> Gateway.Logger.DB.Repo.update()
  end
end
