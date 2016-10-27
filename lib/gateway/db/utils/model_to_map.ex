defmodule Gateway.Utils.ModelToMap do
  @moduledoc """
  Helper functions to turn Model into Map that can be inserted into another Repo with same structure.
  """

  @dropped_keys [
    :__cardinality__,
    :__field__,
    :__owner__,
    :__meta__,
    :__struct__,
    :_id,
    :inserted_at,
    :updated_at,
    :version
  ]

  def convert(value) when is_list(value), do: Enum.map value, &convert/1
  def convert(struct) do
    struct
    |> Map.from_struct
    |> parse_values
  end

  def parse_values(map) when is_map(map) do
    {_, map} = map
    |> Enum.map_reduce(%{}, &_parse/2)

    map
    |> Map.drop(@dropped_keys)
  end

  defp _parse({key, value}, acc) do
    {nil, Map.put(acc, key, _parse(value))}
  end

  defp _parse(%Decimal{} = value) do
    {float, _} = value
    |> Decimal.to_string
    |> Float.parse

    float
  end

  defp _parse(%Date{} = value), do: Date.to_string value
  defp _parse(%DateTime{} = value), do: DateTime.to_string value
  defp _parse(%Ecto.Date{} = value), do: Ecto.Date.to_string value
  defp _parse(%Ecto.DateTime{} = value), do: Ecto.DateTime.to_string value

  defp _parse(value) when is_map(value) do
    case Map.has_key?(value, :__struct__) do
      true -> convert(value)
      _    -> parse_values(value)
    end
  end

  defp _parse(value) when is_list(value) do
    Enum.map(value, &_parse/1)
  end

  defp _parse(value), do: value
end
