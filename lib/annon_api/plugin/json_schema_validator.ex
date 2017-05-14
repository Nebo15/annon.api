defmodule Annon.Plugin.JsonSchemaValidator do
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
        changeset = %{changeset | valid?: false}
        build_changeset_errors(changeset, field, failed_validations)
    end
  end

  defp build_changeset_errors(changeset, field, failed_validations) do
    Enum.reduce(failed_validations, changeset, fn
      {%{description: message, rule: rule, params: params}, json_path}, changeset ->
        fake_field =
          json_path
          |> String.replace_leading("$", Atom.to_string(field))
          |> String.to_atom()

        errors = [{fake_field, {message, [validation: rule]}}] ++ changeset.errors

        validations =
          if changeset.validations,
            do: [{fake_field, {rule, params}}] ++ changeset.validations,
          else: [{fake_field, {rule, params}}]

        %{changeset |
          errors: errors,
          validations: validations}
    end)
  end
end
