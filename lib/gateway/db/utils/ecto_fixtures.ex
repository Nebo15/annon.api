defmodule EctoFixtures do
  @moduledoc """
  Generates :map or JSON fixture from Ecto.Schema
  It's useful for tests
  """

  def ecto_json_fixtures(model) do
    model
    |> ecto_fixtures
    |> Poison.encode!
  end

  def ecto_fixtures(model) when is_map(model), do: map_ecto_values(model)
  def ecto_fixtures(model) do
    Faker.start
    case Keyword.has_key?(model.__info__(:functions), :__schema__) do
      true -> map_ecto_values(model.__schema__(:types))
      false -> raise "not an Ecto.Schema"
    end
  end

  def map_ecto_values(map) when is_map(map) do
    {_, res} = map
    |> Map.delete(:__meta__)
    |> Map.delete(:__struct__)
    |> Enum.map_reduce(%{}, &value_to_json/2)
    res
  end

  defp value_to_json({key, :id}, acc), do: {nil, Map.put(acc, key, :rand.uniform(10_000))}
  defp value_to_json({key, :integer} , acc), do: {nil, Map.put(acc, key, :rand.uniform(10_000))}
  defp value_to_json({key, :decimal} , acc), do: {nil, Map.put(acc, key, random_float)}
  defp value_to_json({key, :boolean} , acc), do: {nil, Map.put(acc, key, random_boolean)}
  defp value_to_json({key, :string} , acc), do: {nil, Map.put(acc, key, Faker.Name.first_name)}
  defp value_to_json({key, :map} , acc), do: {nil, Map.put(acc, key, %{"last_name" => Faker.Name.last_name})}
  defp value_to_json({key, Ecto.DateTime} , acc), do: {nil, Map.put(acc, key, random_date("%FT%T%:z"))}
  defp value_to_json({key, :naive_datetime} , acc), do: {nil, Map.put(acc, key, random_date("%FT%T%:z"))}
  defp value_to_json({key, {:embed, %Ecto.Embedded{cardinality: :one, related: related}}}, acc) do
    {nil, Map.put(acc, key, ecto_fixtures(related))}
  end
  defp value_to_json({key, {:embed, %Ecto.Embedded{cardinality: :many, related: related}}}, acc) do
    {nil, Map.put(acc, key, [ecto_fixtures(related)])}
  end

  def random_date(format), do: Timex.format!(Timex.now, format, :strftime)
  def random_float, do: Float.ceil(:rand.uniform + :rand.uniform(1000), 5)

  def random_boolean do
    Enum.random([true, false])
  end

  def random_enum(module) do
    module.__enum_map__
    |> Enum.random
    |> atom_to_string
  end

  def atom_to_string(val) when is_binary(val), do: val
  def atom_to_string(val) when is_atom(val), do: Atom.to_string val
end

defmodule EctoFixtures.EnumMacro do
  @moduledoc """
  Module for macro
  """
  defmacro enum_value(module) do
    quote do
      defp value_to_json({key, unquote(module) = module}, acc), do: {nil, Map.put(acc, key, random_enum(module))}
    end
  end
end
