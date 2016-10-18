defmodule Gateway.Plugins.Validator do
  @moduledoc """
  Plugin which validates request based on ex_json_schema
  See more https://github.com/jonasschmidt/ex_json_schema
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _), do: valid?(get_body(conn), get_schema(conn), conn)
  def valid?(body, schema, conn) do
    case ExJsonSchema.Validator.validate(schema, body) do
      :ok -> conn
      {:error, errors} -> conn |> send_422(errors) |> halt
    end

  end

  def get_schema(%Plug.Conn{assigns: %{schema: %{} = schema}}), do: schema
  def get_schema(
    %Plug.Conn{
      private: %{
        api_config: %{
          plugins: [
            %{name: "Validator", settings: %{"schema" => schema}}
          ]
        }
      }
    }), do: schema |> Poison.decode!

  def get_schema(_), do: %{}
  def get_body(%Plug.Conn{body_params: %{} = body}), do: body
  defp send_422(conn, errors) do
    conn
     |> put_resp_content_type("application/json")
     |> send_resp(422, create_json_response(errors))
     |> halt
  end
  defp create_json_response(errors) when is_list(errors) do
    Poison.encode!(%{
      meta: %{
        code: 422,
        description: "Validation Errors",
        error: errors |> Enum.map(&map_schema_errors/1)
      }
    })
  end

  defp map_schema_errors({rule, path}) do
    %{
      entry_type: "json_data_property",
      entry: path,
      rules: [%{rule: get_rule_name(rule)}]
    }
  end

  defp get_rule_name("can't be blank"), do: :required
  defp get_rule_name("is invalid"), do: :invalid
  defp get_rule_name(msg), do: msg

end
