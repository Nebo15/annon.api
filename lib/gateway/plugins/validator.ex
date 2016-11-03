defmodule Gateway.Plugins.Validator do
  @moduledoc """
  Plugin which validates request based on ex_json_schema
  See more https://github.com/jonasschmidt/ex_json_schema
  """
  import Plug.Conn
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  def init(opts), do: opts

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> get_enabled()
    |> validate(conn)
  end
  def call(conn, _), do: conn

  defp validate(%Plugin{settings: %{"schema" => schema}}, %Plug.Conn{body_params: %{} = body} = conn) do
    schema
    |> Poison.decode!()
    |> NExJsonSchema.Validator.validate(body)
    |> normalize_validation(conn)
  end
  defp validate(_, conn), do: conn

  defp normalize_validation(:ok, conn), do: conn
  defp normalize_validation({:error, errors}, conn) do
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

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end
  defp filter_plugin(%Plugin{name: :Validator, is_enabled: true}), do: true
  defp filter_plugin(_), do: false

end
