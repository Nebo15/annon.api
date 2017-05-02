defmodule Annon.Configuration.Schemas.Plugin do
  @moduledoc """
  Schema for Plugins settings.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Annon.Validators.Settings
  alias Annon.Configuration.Schemas.Plugin, as: PluginSchema
  alias Annon.Configuration.Schemas.API, as: APISchema

  @type t :: %PluginSchema{
    name: atom,
    is_enabled: boolean,
    settings: map
  }

  @valid_plugin_names [
    "jwt", "validator", "acl", "proxy", "idempotency", "ip_restriction", "ua_restriction", "scopes", "cors"
  ]

  @derive {Poison.Encoder, except: [:__meta__, :api]}
  schema "plugins" do
    field :name, :string
    field :is_enabled, :boolean, default: false
    field :settings, :map

    belongs_to :api, APISchema, type: :binary_id

    timestamps()
  end

end
