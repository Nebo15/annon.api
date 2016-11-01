defmodule Gateway.DB do
  @moduledoc """
  Shortener for models definitions.
  """
  import Ecto.Changeset
  alias Ecto.Changeset
require Logger

  def model do
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

  def validate_settings(%Changeset{changes: %{name: :JWT, settings: %{"signature" => signature}}} = ch)
        when is_binary(signature) and byte_size(signature) <= 256 do
    ch
    |> put_change(:settings, %{"signature" => signature})
  end  
  def validate_settings(%Changeset{changes: %{name: :JWT, settings: %{"signature" => signature}}} = ch) do
    add_error(ch, :settings, "JWT settings field 'signature' must be a string with binary length <= 256")
  end
  def validate_settings(%Changeset{changes: %{name: :JWT}} = ch) do
    add_error(ch, :settings, "JWT settings required field 'signature'")
  end
  def validate_settings(ch), do: ch

  def validate_map(%Changeset{} = ch, field) do
    ch
    |> get_field(field)
    |> validate_map_size(ch, field)
    |> validate_map
  end

  def normalize_ecto_delete({0, _}), do: nil
  def normalize_ecto_delete({1, _}), do: {:ok, nil}

  def normalize_ecto_update({0, _}), do: nil
  def normalize_ecto_update({1, [schema]}), do: schema
  def normalize_ecto_update({:error, ch}), do: {:error, ch}

  defp validate_map_size(map, ch, field) when is_map(map) and map_size(map) <= 128, do: {ch, map, field}
  defp validate_map_size(nil, ch, field), do: {ch, nil, field}
  defp validate_map_size(_map, ch, field) do
    add_error(ch, field, "amount of the map elements must be <= 128")
  end

  defp validate_map(%Changeset{} = ch), do: ch
  defp validate_map({%Changeset{} = ch, nil, _field}), do: ch
  defp validate_map({%Changeset{} = ch, map, field}) when is_map(map) do
    {_, ch} = Enum.map_reduce(map, ch, fn({key, value}, acc) ->
      acc = acc
      |> validate_map_key(key, field)
      |> validate_map_value(value, field)
      {nil, acc}
    end)
    ch
  end

  defp validate_map_key(ch, key, _field) when is_number(key) and key <= 999_999_999_999, do: ch
  defp validate_map_key(ch, key, _field) when is_binary(key) and byte_size(key) <= 64, do: ch
  defp validate_map_key(ch, _key, field) do
    add_error(ch, field, "key must be a string with binary length <= 64")
  end

  defp validate_map_value(ch, value, _field) when is_number(value) and value <= 999_999_999_999, do: ch
  defp validate_map_value(ch, value, _field) when is_binary(value) and byte_size(value) <= 2048, do: ch
  defp validate_map_value(ch, value, _field) when is_list(value), do: ch
  defp validate_map_value(ch, _value, field) do
    add_error(ch, field, "value must be a string with binary length <= 2048")
  end
end
