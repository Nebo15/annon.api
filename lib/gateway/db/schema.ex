defmodule Gateway.DB.Schema do
  @moduledoc """
  Shortener for Schemas definitions.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end
end
