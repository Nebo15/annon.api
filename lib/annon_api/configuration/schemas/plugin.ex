defmodule Annon.Configuration.Schemas.Plugin do
  @moduledoc """
  Schema for Plugins settings.
  """
  use Ecto.Schema
  alias Annon.Configuration.Schemas.API, as: APISchema

  @derive {Poison.Encoder, except: [:__meta__, :api]}
  schema "plugins" do
    field :name, :string
    field :is_enabled, :boolean, default: false
    field :settings, :map

    belongs_to :api, APISchema, type: :binary_id

    timestamps(type: :utc_datetime)
  end
end
