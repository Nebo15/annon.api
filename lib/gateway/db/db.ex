defmodule Gateway.DB do
  @moduledoc """
  Shortener for schemas definitions.
  """

  def schema do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Gateway.DB
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
