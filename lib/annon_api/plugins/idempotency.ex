defmodule Annon.Plugins.Idempotency do
  @moduledoc """
  [Request Idempotency plugin](http://docs.annon.apiary.io/#reference/plugins/idempotency).
  """
  use Annon.Plugin, plugin_name: "idempotency"
  alias Annon.Requests.Log
  alias Annon.Requests.Request, as: RequestSchema
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response

  @idempotent_methods ["POST"]

  def validate_settings(changeset),
    do: changeset

  def settings_validation_schema,
    do: %{}

  def execute(%Conn{method: method, body_params: params} = conn, _request, _settings)
    when method in @idempotent_methods do
    conn
    |> Conn.get_req_header("x-idempotency-key")
    |> load_log_request
    |> validate_request(params)
    |> normalize_resp(conn)
  end
  def execute(%Conn{} = conn, _request, _settings),
    do: conn

  defp load_log_request([key|_]) when is_binary(key) do
    Log.get_request_by(idempotency_key: key)
  end
  defp load_log_request(_), do: nil

  defp validate_request({:ok, %RequestSchema{request: %{body: body}} = log_request}, params) do
    {Map.equal?(params, body), log_request}
  end
  defp validate_request(_, _params), do: nil

  defp normalize_resp({true, %RequestSchema{response: %{headers: headers, body: body}, status_code: status_code}}, conn)
    do
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
    |> Response.send(conn, 409)
    |> Response.halt()
  end
  defp normalize_resp(_, conn), do: conn

  defp format_headers([]), do: []
  defp format_headers([map|t]), do: [Enum.at(map, 0)] ++ format_headers(t)
end
