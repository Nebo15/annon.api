defmodule Gateway.Plugins.Idempotency do
  @moduledoc """
  Plugin for request idempotency.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: :idempotency

  alias Plug.Conn
  alias EView.Views.Error, as: ErrorView
  alias Gateway.DB.Schemas.Log
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APIModel # TODO: rename APIModel to APISchema
  alias Gateway.HTTPHelpers.Response

  @idempotent_methods ["POST"]

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(%Plugin{}, %Plug.Conn{method: method, body_params: params} = conn) when method in @idempotent_methods do
    conn
    |> Conn.get_req_header("x-idempotency-key")
    |> load_log_request
    |> validate_request(params)
    |> normalize_resp(conn)
  end
  defp execute(_, conn), do: conn

  defp load_log_request([key|_]) when is_binary(key) do
    Log.get_by([idempotency_key: key])
  end
  defp load_log_request(_), do: nil

  defp validate_request(%Gateway.DB.Schemas.Log{request: %{body: body}} = log_request, params) do
    {Map.equal?(params, body), log_request}
  end
  defp validate_request(_, _params), do: nil

  defp normalize_resp({true, %Gateway.DB.Schemas.Log{response: %{headers: headers, body: body},
                                                     status_code: status_code}}, conn) do
    conn
    |> Conn.merge_resp_headers(format_headers(headers))
    |> Conn.send_resp(status_code, body)
    |> Conn.halt
  end
  defp normalize_resp({false, _}, conn) do
    "409.json"
    |> ErrorView.render(%{
      message: "You sent duplicate idempotency key but request params was different.",
      type: :idempotency_key_duplicated,
      invalid: [%{
        entry_type: "header",
        entry: "X-Idempotency-Key",
        rules: [:unique]
      }]
    })
    |> Response.render_response(conn, 409)
    |> Conn.halt
  end
  defp normalize_resp(_, conn), do: conn

  defp format_headers([]), do: []
  defp format_headers([map|t]), do: [Enum.at(map, 0)] ++ format_headers(t)
end
