defmodule Annon.Helpers.JsonSchemaValidator do
  @moduledoc """
  This module provides [JSON Schema](http://json-schema.org/) validator for a plugin settings.

  All rules is stored in `Annon.Validators.Settings`.
  """
  import Ecto.Changeset, only: [fetch_change: 2]

  def validate_with_json_schema(changeset, field, schema) do
    case fetch_change(changeset, field) do
      {:ok, change} ->
        validate_change(changeset, field, change, schema)
      :error ->
        changeset
    end
  end

  defp validate_change(changeset, field, change, schema) do
    case NExJsonSchema.Validator.validate(schema, change) do
      :ok ->
        changeset
      {:error, failed_validations} ->
        %{changeset |
          valid?: false,
          errors: build_changeset_errors(field, failed_validations) ++ changeset.errors}
    end
  end

  defp build_changeset_errors(field, failed_validations) do
    failed_validations
    |> Enum.map_reduce([], fn({%{description: message, rule: rule}, _}, acc) ->
      {nil, Keyword.put(acc, field, {message, [validation: rule]})}
    end)
    |> elem(1)
  end
end
