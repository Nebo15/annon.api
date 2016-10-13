defmodule Gateway.DB.Models.Plugin do
  @moduledoc """
  Model for address
  """
  use Gateway.DB, :model
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
    |> cast(params, [:name, :settings])
    |> assoc_constraint(:api)
    |> unique_constraint(:api_id_name)
    |> validate_required([:name, :settings])
    |> validate_map(:settings)
  end

  defp create(nil, _params), do: nil
  defp create(%APIModel{} = api, params) when is_map(params) do
    api
    |> Ecto.build_assoc(:plugins)
    |> Plugin.changeset(params)
    |> Repo.insert
  end

  defp update(api_id, name, params) when is_map(params) do
    %Plugin{}
    |> Plugin.changeset(params)
    |> update_plugin(api_id, name)
    |> normalize_ecto_update_resp
  end
  defp update(%Ecto.Changeset{valid?: true, changes: changes}, api_id, name) do
    query = from(p in Plugin, where: p.api_id == ^api_id, where: p.name == ^name)
    Repo.update_all(query, [set: Map.to_list(changes)], returning: true)
  end
  defp update_plugin(%Ecto.Changeset{valid?: false} = ch), do: {:error, ch}
end
