defmodule Gateway.Changeset.Validator.JsonSchema do
  @moduledoc """
    This module provides Changeset validation via json schema.
  """

  import Ecto.Changeset, only: [get_change: 3]

  def validate_via_json_schema(changeset, field, schema) do
    changeset
    |> get_change(field, nil)
    |> validate_json(schema)
    |> prepare_errors(field)
    |> put_errors(changeset)
  end

  defp validate_json(nil, _schema), do: :ok
  defp validate_json(value, schema), do: NExJsonSchema.Validator.validate(schema, value)

  defp prepare_errors(:ok, _field), do: :ok
  defp prepare_errors({:error, messages}, field) do
    messages
    |> Enum.map_reduce([], fn({%{description: message, rule: rule}, _}, acc) ->
      {nil, Keyword.put(acc, field, {message, [validation: rule]})}
    end)
    |> elem(1)
  end

  defp put_errors(:ok, changeset), do: changeset
  defp put_errors(new_errors, %{errors: errors} = changeset) do
    %{changeset | errors: new_errors ++ errors, valid?: false}
  end
end
