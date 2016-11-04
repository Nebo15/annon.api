defmodule Gateway.Plugins.Logger do
  @moduledoc """
  Request/response logger plug.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "logger"

  alias Plug.Conn
  alias Gateway.DB.Schemas.Log
  alias Gateway.DB.Schemas.API, as: APISchema

  def call(conn, _opts) do
    conn
    |> log_request()
    |> Conn.register_before_send(fn conn ->
      conn
      |> log_response()
    end)
  end

  defp log_request(conn) do
    %{
      id: get_request_id(conn),
      idempotency_key: get_idempotency_key(conn) || "",
      ip_address: conn.remote_ip |> Tuple.to_list |> Enum.join("."),
      request: get_request_data(conn)
    }
    |> Log.create

    conn
  end

  defp log_response(conn) do
    conn
    |> get_request_id()
    |> Log.put_response(%{
      api: get_api_data(conn),
      consumer: get_consumer_data(conn),
      response: get_response_data(conn),
      latencies: get_latencies_data(conn),
      status_code: conn.status
    })

    conn
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

  defp get_api_data(%Plug.Conn{private: %{api_config: nil}}), do: %{}
  defp get_api_data(%Plug.Conn{private: %{api_config: %APISchema{id: id, name: name, request: request}}}) do
    %{
      id: id,
      name: name,
      request: request
    }
  end

  defp get_consumer_data(_conn), do: %{} |> prepare_params

  defp get_request_data(conn) do
    %{
      method: conn.method,
      uri: conn.request_path,
      query: conn.query_string,
      headers: modify_headers_list(conn.req_headers),
      body: conn.body_params
    }
    |> prepare_params
  end

  defp get_response_data(conn) do
    %{
      status_code: conn.status,
      headers: modify_headers_list(conn.resp_headers),
      body: conn.resp_body
    }
    |> prepare_params
  end

  defp get_latencies_data(conn) do
    %{
      gateway: conn.assigns.latencies_gateway,
      upstream: "",
      client_request: ""
    }
    |> prepare_params
  end

  defp get_key(key) when is_binary(key), do: String.to_atom(key)
  defp get_key(key) when is_atom(key), do: key

  defp prepare_params(params) when params == nil, do: %{}
  defp prepare_params(params), do: for {key, val} <- params, into: %{}, do: {get_key(key), val}
end
