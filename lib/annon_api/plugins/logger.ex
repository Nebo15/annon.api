defmodule Annon.Plugins.Logger do
  @moduledoc """
  This plugin stores reqests and responses in `Logger` database.
  It is enabled by default and can not be disabled without rebuilding Annon container.

  All stored records can be accessible via [management API](http://docs.annon.apiary.io/#reference/requests).
  """
  use Annon.Plugin, plugin_name: :logger
  alias Annon.Requests.Log
  require Logger
  alias Annon.Helpers.Conn, as: ConnHelpers

  def validate_settings(changeset),
    do: changeset

  def settings_validation_schema,
    do: %{}

  def execute(%Conn{} = conn, %{api: api}, _settings) do
    Conn.register_before_send(conn, &log_request(&1, api))
  end

  defp log_request(%Conn{} = conn, api) do
    request = %{
      id: ConnHelpers.get_request_id(conn, nil),
      idempotency_key: ConnHelpers.get_idempotency_key(conn, ""),
      ip_address: conn.remote_ip |> Tuple.to_list |> Enum.join("."),
      request: get_request_data(conn),
      api: get_api_data(api),
      response: get_response_data(conn),
      latencies: Map.take(conn.assigns.latencies, [:client_request, :upstream, :gateway]),
      status_code: conn.status
    }

    case Log.create_request(request) do
      {:ok, _} ->
        conn
      {:error, error} ->
        Logger.warn fn -> "Can not save request information. Changeset: #{inspect error}" end
        conn
    end
  end

  defp modify_headers_list([]), do: []
  defp modify_headers_list([{key, value}|t]), do: [%{key => value}] ++ modify_headers_list(t)

  defp get_api_data(nil),
    do: nil
  defp get_api_data(%{id: id, name: name, request: request}) do
    %{
      id: id,
      name: name,
      request: Map.take(request, [:scheme, :host, :port, :path, :methods])
    }
  end

  defp get_request_data(conn) do
    %{
      method: conn.method,
      uri: conn.request_path,
      query: Plug.Conn.Query.decode(conn.query_string),
      headers: modify_headers_list(conn.req_headers),
      body: Poison.encode!(conn.body_params)
    }
  end

  defp get_response_body(conn) do
    conn
    |> Conn.get_resp_header("content-disposition")
    |> Enum.at(0)
    |> process_content_disposition(conn)
  end

  defp process_content_disposition("inline; filename=" <> _, _conn), do: "inline; filename=..."
  defp process_content_disposition(nil, conn), do: conn.resp_body
  defp process_content_disposition(_, conn), do: conn.resp_body

  defp get_response_data(conn) do
    %{
      status_code: conn.status,
      headers: modify_headers_list(conn.resp_headers),
      body: get_response_body(conn)
    }
  end
end
