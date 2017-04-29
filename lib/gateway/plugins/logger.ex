defmodule Annon.Plugins.Logger do
  @moduledoc """
  This plugin stores reqests and responses in `Logger` database.
  It is enabled by default and can not be disabled without rebuilding Annon container.

  All stored records can be accessible via [management API](http://docs.annon.apiary.io/#reference/requests).
  """
  use Annon.Helpers.Plugin,
    plugin_name: "logger"

  alias Plug.Conn
  alias Annon.DB.Schemas.Log
  alias Annon.DB.Schemas.API, as: APISchema
  require Logger

  @doc false
  def call(conn, _opts) do
    conn
    |> Conn.register_before_send(fn conn ->
      conn
      |> log_request()
    end)
  end

  defp log_request(conn) do
    log = %{
      id: get_request_id(conn),
      idempotency_key: get_idempotency_key(conn) || "",
      ip_address: conn.remote_ip |> Tuple.to_list |> Enum.join("."),
      request: get_request_data(conn),
      api: get_api_data(conn),
      response: get_response_data(conn),
      latencies: get_latencies_data(conn),
      status_code: conn.status
    }

    case Log.create_request(log) do
      {:ok, _} ->
        conn
      {:error, error} ->
        Logger.warn fn -> "Can not save request information. Changeset: #{inspect error}" end
        conn
    end
  end

  defp get_request_id(conn) do
    conn
    |> Conn.get_resp_header("x-request-id")
    |> Enum.at(0)
  end

  defp get_idempotency_key(conn) do
    conn
    |> Conn.get_req_header("x-idempotency-key")
    |> Enum.at(0)
  end

  defp modify_headers_list([]), do: []
  defp modify_headers_list([{key, value}|t]), do: [%{key => value}] ++ modify_headers_list(t)

  defp get_api_data(%Plug.Conn{private: %{api_config: nil}}), do: nil
  defp get_api_data(%Plug.Conn{private: %{api_config: %APISchema{id: id, name: name, request: request}}}) do
    %{
      id: id,
      name: name,
      request: prepare_params(request)
    }
  end

  defp get_request_data(conn) do
    %{
      method: conn.method,
      uri: conn.request_path,
      query: Plug.Conn.Query.decode(conn.query_string),
      headers: modify_headers_list(conn.req_headers),
      body: conn.body_params
    }
    |> prepare_params
  end

  defp get_response_body(conn) do
    conn
    |> Conn.get_resp_header("content-disposition")
    |> Enum.at(0)
    |> process_content_disposition(conn)
  end

  defp process_content_disposition("inline; filename=" <> _, _conn), do: nil
  defp process_content_disposition(nil, conn), do: conn.resp_body
  defp process_content_disposition(_, conn), do: conn.resp_body

  defp get_response_data(conn) do
    %{
      status_code: conn.status,
      headers: modify_headers_list(conn.resp_headers),
      body: get_response_body(conn)
    }
    |> prepare_params
  end

  defp get_latencies_data(conn) do
    %{
      gateway: Map.get(conn.assigns, :latencies_gateway),
      upstream: Map.get(conn.assigns, :latencies_upstream),
      client_request: Map.get(conn.assigns, :latencies_client)
    }
    |> prepare_params
  end

  defp prepare_params(nil), do: %{}
  defp prepare_params(%{__struct__: _} = params), do: params |> Map.delete(:__struct__) |> prepare_params()
  defp prepare_params(params), do: for {key, val} <- params, into: %{}, do: {key_to_atom(key), val}

  defp key_to_atom(key) when is_binary(key), do: String.to_atom(key)
  defp key_to_atom(key) when is_atom(key), do: key
end
