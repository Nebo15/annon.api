defmodule Gateway.DB do
  @moduledoc """
  Shortener for models definitions.
  """
  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      def validate_map(a, b, c)do
        IO.inspect a
        IO.inspect b
        IO.inspect c
      end

      def validate_map(changeset, field) do
        changeset
        |> get_field(field)
        |> Enum.map_reduce(changeset, fn({key, value}, acc) ->
          acc
          |> validate_map_key(key, field)
          |> validate_map_value(value, field)
        end)
      end

      defp validate_map_key(changeset, key, _field) when is_binary(key) and byte_size(key) <= 64, do: changeset
      defp validate_map_key(changeset, key, field) do
        add_error(changeset, field, "key must be a string with binary length <= 64")
      end

      defp validate_map_value(changeset, value, _field) when is_binary(value) and byte_size(value) <= 512, do: changeset
      defp validate_map_value(changeset, value, field) do
        add_error(changeset, field, "value must be a string with binary length <= 512")
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
