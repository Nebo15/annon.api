defmodule Gateway.DB do
  @moduledoc """
  Shortener for schemas definitions.
  """
  import Ecto.Changeset
  alias Ecto.Changeset

  def schema do
    quote do
      use Ecto.Schema

      import Ecto
      import Changeset
      import Ecto.Query
      import Gateway.DB
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def normalize_ecto_delete({0, _}), do: nil
  def normalize_ecto_delete({1, _}), do: {:ok, nil}

  def normalize_ecto_update({0, _}), do: nil
  def normalize_ecto_update({1, [updated_schema]}), do: updated_schema
  def normalize_ecto_update({:error, ch}), do: {:error, ch}
end
