defmodule Gateway.HTTPHelpers.Response do
  # TODO: refactor once https://github.com/Nebo15/eview stabilizes

  def render_create_response(resource) do
    code = 201

    response_body = %{
      meta: %{
        code: code
      },
      data: resource
    }

    { code, Poison.encode!(response_body) }
  end

  def render_show_response(resource) do
    code = 200

    response_body = %{
      meta: %{
        code: code
      },
      data: resource
    }

    { code, Poison.encode!(response_body) }
  end

  def render_not_found_response() do
    code = 404

    response_body = %{
      meta: %{
        code: code,
        description: "The requested API doesn’t exist."
      }
    }

    { code, Poison.encode!(response_body) }
  end

  def render_errors_response(changeset) do
    code = 422

    errors =
      for {field, {error, _}} <- changeset.changes.request.errors, into: %{} do
        {to_string(field), error}
      end

    response_body = %{
      meta: %{
        code: code,
        description: "Validation errors",
        errors: errors
      }
    }

    { code, response_body }
  end

  def render_delete_response(resource) do
    code = 200

    response_body = %{
      meta: %{
        code: code,
        description: "Resource was deleted",
      },
      data: resource
    }

    { code, Poison.encode!(response_body) }
  end
end
