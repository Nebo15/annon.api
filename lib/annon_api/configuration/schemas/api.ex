defmodule Annon.Configuration.Schemas.API do
  @moduledoc """
  Schema for API's entity.
  """
  use Ecto.Schema

  @derive {Poison.Encoder, except: [:__meta__, :plugins]}
  @primary_key {:id, :binary_id, autogenerate: false}
  schema "apis" do
    field :name, :string

    embeds_one :request, Request, primary_key: false, on_replace: :update do
      field :scheme, :string
      field :host, :string
      field :port, :integer
      field :path, :string
      field :methods, {:array, :string}
    end

    has_many :plugins, Annon.Configuration.Schemas.Plugin

    timestamps(type: :utc_datetime)
  end
end
