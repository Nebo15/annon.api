defmodule Gateway.DB.Models.Plugin do
  @moduledoc """
  Model for address
  """
  use Gateway.DB, :model
  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  @derive {Poison.Encoder, except: [:__meta__, :api]}

  schema "plugins" do
    field :name, :string
    field :settings, :map
    belongs_to :api, APIModel

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:api_id, :name, :settings])
    |> assoc_constraint(:api)
    |> unique_constraint(:api_id_name)
    |> validate_required([:name, :settings])
    |> validate_map(:settings)
  end

  def create(api_id, params) when is_map(params) do
    %Gateway.DB.Models.Plugin{ api_id: api_id }
    |> changeset(params)
    |> Repo.insert
  end

  def update(struct, params) do
    struct
    |> changeset(params)
    |> Repo.update
  end

  def delete(struct) do
    struct
    |> Repo.delete
  end

  defp normalize_ecto_delete_resp({0, _}), do: nil
  defp normalize_ecto_delete_resp({1, _}), do: {:ok, nil}

  defp normalize_ecto_update_resp({0, _}), do: nil
  defp normalize_ecto_update_resp({1, [struct]}), do: struct
  defp normalize_ecto_update_resp({:error, ch}), do: {:error, ch}
end
