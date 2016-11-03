defmodule Gateway.DB.Models.Request do
  @moduledoc """
    Request embed entity
  """
  use Gateway.DB, :model

  embedded_schema do
    field :scheme, :string
    field :host, :string
    field :port, :integer
    field :path, :string
    field :method, :string
  end

  def changeset_proxy(api, params \\ %{}) do
    api
    |> cast(params, [:scheme, :host, :port, :path, :method])
    |> validate_required([:host])
    |> validate_format(:scheme, ~r/^(http|https)$/)
  end
end
