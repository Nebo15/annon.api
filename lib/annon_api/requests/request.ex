defmodule Annon.Requests.Request do
  @moduledoc """
  Schema for Requests Log.
  """
  use Ecto.Schema

  @derive {Poison.Encoder, except: [:__meta__]}
  @primary_key {:id, :string, autogenerate: false}
  schema "requests" do
    embeds_one :api, API, primary_key: false do
      field :id, :string
      field :name, :string

      embeds_one :request, Request, primary_key: false do
        field :scheme, :string
        field :host, :string
        field :port, :integer
        field :path, :string
      end
    end

    embeds_one :request, HTTPRequest, primary_key: false do
      field :method, :string
      field :uri, :string
      field :query, :map
      field :headers, {:array, :map}
      field :body, :map
    end

    embeds_one :response, HTTPResponse, primary_key: false do
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

    timestamps(type: :utc_datetime)
  end
end
