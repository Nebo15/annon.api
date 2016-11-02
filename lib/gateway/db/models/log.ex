defmodule Gateway.DB.Models.Log do
  @moduledoc """
  Log record DB entity
  """
  use Gateway.DB, :model
  alias Gateway.DB.Logger.Repo

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
      field :headers, :map
      field :body, :map
    end

    embeds_one :response, Response, primary_key: false do
      field :status_code, :string
      field :headers, :map
      field :body, :map
    end

    embeds_one :latencies, Latencies, primary_key: false do
      field :gateway, :string
      field :upstream, :string
      field :client_request, :string
    end

    field :idempotency_key, :string
    field :ip_address, :string
    field :status_code, :integer

    timestamps()
  end

#  def changeset_request(api, params \\ %{}) do
#    api
#    |> cast(params, [:api, :consumer, :idempotency_key, :ip_address, :request, :response, :latencies, :status_code])
#    |> validate_required([:ip_address, :request])
#  end

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
    |> cast(params, [:scheme, :host, :port, :path, :body])
  end

  def changeset_embeded_consumer(data, params \\ %{}) do
    data
    |> cast(params, [:id, :external_id, :metadata])
  end  

  def create(params \\ %{}) do
    %Gateway.DB.Models.Log{}
    |> cast(params, [:id, :idempotency_key, :ip_address])
    |> cast_embed(:request, with: &changeset_embeded_request/2)
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

  def get_by(selector) do
    Repo.one from Gateway.DB.Models.Log,
    where: ^selector,
    limit: 1
  end

  def get_records do
    Repo.all(from record in Gateway.DB.Models.Log)
  end

  def get_records(limit) when is_integer(limit) do
    Repo.all(from record in Gateway.DB.Models.Log, limit: ^limit)
  end
end
