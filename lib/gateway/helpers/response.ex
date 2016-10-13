defmodule Gateway.HTTPHelpers.Response do
  @moduledoc """
  Response helper
  """
  # TODO: refactor once https://github.com/Nebo15/eview stabilizes

  def render_create_response({:ok, resource}), do: render_response(resource, 201)
  def render_create_response({:error, changeset}), do: render_errors_response(changeset)
  def render_create_response(nil), do: render_not_found_response()

  def render_show_response({:ok, resource}), do: render_response(resource, 200)
  def render_show_response({:error, changeset}), do: render_errors_response(changeset)
  def render_show_response(nil), do: render_not_found_response()
  def render_show_response(resource), do: render_response(resource, 200)

  def render_delete_response({:ok, resource}), do: render_response(resource, 200, "Resource was deleted")
  def render_delete_response(_), do: render_not_found_response

  def render_not_found_response(msg \\ "The requested API doesn’t exist") when is_binary msg do
    encode_response(%{
      meta: %{
        code: 404,
        description: msg
      }
    })
  end

  def render_errors_response(changeset) do
    code = 422

    errors = Ecto.Changeset.traverse_errors(changeset, fn
      msg -> err_detail(msg)
    end)

    response_body = %{
      meta: %{
        code: code,
        description: "Validation errors",
        errors: errors
      }
    }

    encode_response(response_body)
  end

  defp err_detail({message, values}) do
    Enum.reduce values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end
  defp err_detail(message), do: message

  def render_response(resource, code) do
    resource
    |> response_struct(code)
    |> encode_response
  end

  def render_response(resource, code, description) do
    resource
    |> response_struct(code)
    |> put_description(description)
    |> encode_response
  end

  def response_struct(resource, code) do
    %{
      meta: %{
        code: code
      },
      data: resource
    }
  end

  def put_description(%{meta: meta} = struct, text) do
    struct
    |> Map.put(:meta, Map.put(meta, :description, text))
  end

  def encode_response(%{meta: %{code: code}} = struct) do
    {code, Poison.encode!(struct)}
  end
end
