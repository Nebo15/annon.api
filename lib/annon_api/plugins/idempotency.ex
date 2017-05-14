defmodule Annon.Plugins.Idempotency do
  @moduledoc """
  [Request Idempotency plugin](http://docs.annon.apiary.io/#reference/plugins/idempotency).
  """
  use Annon.Plugin, plugin_name: :idempotency
  alias Annon.Requests.Log
  alias Annon.Requests.Request, as: RequestSchema
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response

  @idempotent_methods ["POST"]

  def validate_settings(changeset),
    do: changeset

  def settings_validation_schema,
    do: %{}

  def execute(%Conn{method: method, body_params: request_body} = conn, _request, _settings)
    when method in @idempotent_methods do
    with {:ok, idempotency_key} <- Annon.Helpers.Conn.fetch_idempotency_key(conn),
         {:ok, saved_request} <- Log.get_request_by(idempotency_key: idempotency_key),
         true <- request_body_equal?(request_body, saved_request) do

      %RequestSchema{response: %{headers: headers, body: body}, status_code: status_code} = saved_request

      conn
      |> Conn.merge_resp_headers(format_headers(headers))
      |> Conn.send_resp(status_code, body)
      |> Conn.halt()
    else
      :error -> conn
      {:error, :not_found} -> conn
      false -> render_duplicate_idempotency_key(conn)
    end
  end
  def execute(%Conn{} = conn, _request, _settings),
    do: conn

  defp request_body_equal?(body_params, %RequestSchema{request: %{body: body}}) do
    case Poison.decode(body) do
      {:ok, request_body_params} -> Map.equal?(body_params, request_body_params)
      {:error, _} -> false
    end
  end

  defp render_duplicate_idempotency_key(conn) do
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

  defp format_headers([]),
    do: []
  defp format_headers([head | t]),
    do: [Enum.at(head, 0)] ++ format_headers(t)
end
