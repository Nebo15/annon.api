defmodule Gateway.DB.Schemas.Log do
  @moduledoc """
  Log record DB entity
  """
  use Gateway.DB, :schema
  alias Gateway.DB.Logger.Repo
  alias Gateway.DB.Schemas.Log, as: LogSchema

  @derive {Poison.Encoder, except: [:__meta__]}
  @primary_key {:id, :string, autogenerate: false}
  schema "logs" do
    embeds_one :api, API, primary_key: false do
      field :name, :string
      embeds_one :request, Request, primary_key: false do
        field :scheme, :string
        field :host, :string
        field :port, :integer
        field :path, :string
      end
    end

    embeds_one :consumer, Consumer, primary_key: false do
      field :id, :string
      field :external_id, :string
      field :metadata, :map
    end

    embeds_one :request, Request, primary_key: false do
      field :method, :string
      field :uri, :string
      field :query, :map
      field :headers, {:array, :map}
      field :body, :map
    end

    embeds_one :response, Response, primary_key: false do
      field :status_code, :integer
      field :headers, {:array, :map}
      field :body, :string
    end

    embeds_one :latencies, Latencies, primary_key: false do
      field :gateway, :integer
      field :upstream, :integer
      field :client_request, :integer
    end

    field :idempotency_key, :string
    field :ip_address, :string
    field :status_code, :integer

    timestamps()
  end

  def changeset_request(struct, params \\ %{}) do
    struct
    |> cast(params, [:id, :idempotency_key, :ip_address])
    |> cast_embed(:request, with: &changeset_embeded_request/2)
  end

  def changeset_response(api, params \\ %{}) do
    api
    |> cast(params, [:idempotency_key, :ip_address, :status_code])
    |> cast_embed(:api, with: &changeset_embeded_api/2)
    |> cast_embed(:consumer, with: &changeset_embeded_consumer/2)
    |> cast_embed(:request, with: &changeset_embeded_request/2)
    |> cast_embed(:response, with: &changeset_embeded_response/2)
    |> cast_embed(:latencies, with: &changeset_embeded_latencies/2)
    |> validate_required([:api, :consumer, :latencies, :response, :status_code])
  end

  def changeset_embeded_request(data, params \\ %{}) do
    data
    |> cast(params, [:method, :uri, :query, :headers, :body])
  end

  def changeset_embeded_response(data, params \\ %{}) do
    data
    |> cast(params, [:status_code, :headers, :body])
  end

  def changeset_embeded_latencies(data, params \\ %{}) do
    data
    |> cast(params, [:gateway, :upstream, :client_request])
  end

  def changeset_embeded_api(data, params \\ %{}) do
    data
    |> cast(params, [:name])
    |> cast_embed(:request, with: &changeset_embeded_api_request/2)
  end

  def changeset_embeded_api_request(data, params \\ %{}) do
    data
    |> cast(params, [:scheme, :host, :port, :path])
  end

  def changeset_embeded_consumer(data, params \\ %{}) do
    data
    |> cast(params, [:id, :external_id, :metadata])
  end

  def get_one_by(selector) do
    Repo.one from LogSchema,
      where: ^selector,
      limit: 1
  end

  def create_request(params) when is_map(params) do
    %LogSchema{}
    |> changeset_request(params)
    |> Repo.insert
  end

  def put_response(request_id, params) when is_map(params) do
    try do
      %LogSchema{id: request_id}
      |> changeset_response(params)
      |> Repo.update()
    rescue
      Ecto.StaleEntryError -> nil
    end
  end

  def delete(request_id) do
    Repo.delete_all from a in LogSchema,
      where: a.id == ^request_id
  end
end
