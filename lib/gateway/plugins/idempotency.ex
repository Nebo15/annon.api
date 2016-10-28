defmodule Gateway.Plugins.Idempotency do
  @moduledoc """
    Plugin for Idempotency
  """
  import Plug.Conn

  alias Gateway.DB.Models.Log
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel
require Logger
  def init([]), do: false

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> get_enabled()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(%Plugin{}, %Plug.Conn{method: "POST", body_params: params} = conn) do
    conn
    |> get_req_header("x-idempotency-key")
    |> load_log_request
    |> validate_request(params)
    |> normalize_resp(conn)
  end
  defp execute(_, conn), do: conn

  defp load_log_request([key]) when is_binary(key) do
    Log.get_record_by([idempotency_key: key])
  end
  defp load_log_request(_), do: nil

  defp validate_request(%Gateway.DB.Models.Log{request: %{"body" => body}} = log_request, params) do
    {Map.equal?(params, body), log_request}
  end
  defp validate_request(_, _params), do: nil

  defp normalize_resp({true, %Gateway.DB.Models.Log{response: %{"headers" => headers, "body" => body},
                                                    status_code: code}}, conn) do
    conn
    |> merge_resp_headers(format_headers(headers))
    |> send_resp(code, body)
    |> halt
  end
  defp normalize_resp({false, _}, conn), do: conn |> send_halt(409, "different POST parameters")
  defp normalize_resp(_, conn), do: conn

  defp send_halt(conn, code, message) do
    conn
    |> send_resp(code, create_json_response(code, message))
    |> halt
  end

  defp create_json_response(code, message) do
    Poison.encode!(%{
      meta: %{
        code: code,
        error: message
      }
    })
  end

  defp format_headers([]), do: []
  defp format_headers([map|t]), do: [Enum.at(map, 0)] ++ format_headers(t)

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end
  defp filter_plugin(%Plugin{name: :Idempotency, is_enabled: true}), do: true
  defp filter_plugin(_), do: false
end
