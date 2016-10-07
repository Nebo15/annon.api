defmodule Gateway.DB.Models.Plugin do
  @moduledoc """
  Model for address
  """
  use Gateway.DB, :model

#  @derive {Poison.Encoder, except: [:__meta__, :portfolio_subscription]}

  schema "plugins" do
     field :name, :string
     field :settings, :map
#     belongs_to :api_id, Gateway.DB.Models.Api

     timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
#    |> cast(params, [:name, :settings, :api_id])
    |> cast(params, [:name, :settings])
    |> validate_required([:name, :settings])
    |> validate_map(:settings)
#    |> assoc_constraint(:api_id)
  end
end
