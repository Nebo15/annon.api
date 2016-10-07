defmodule Gateway.DB.API do
  @moduledoc """
  API DB entity
  """

  use Ecto.Schema

  schema "apis" do
    field :name, :string
    field :scheme, :string
    field :host, :string
    field :port, :string
    field :path, :string

    timestamps()
  end

  @required_fields [:scheme, :host, :port, :path]

  def changeset(api, params \\ %{}) do
    api
    |> Ecto.Changeset.cast(params, @required_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
  end

  def create(params) do
    api = %Gateway.DB.API{}
    changeset = changeset(api, params)
    Gateway.DB.Repo.insert(changeset)
  end
end
