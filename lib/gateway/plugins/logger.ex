defmodule Gateway.Plugins.Logger do
  @moduledoc """
  Request/response logger plug
  """

  import Plug.Conn
  alias Gateway.DB.Logger.Repo
  alias Gateway.DB.Models.Log
  alias EctoFixtures

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    log(conn, :request)
    conn = register_before_send(conn, fn conn ->
      log(conn, :response)
      conn
    end)
    conn
  end

  defp log(conn, :request) do
    id = conn
    |> get_resp_header("x-request-id")
    |> Enum.at(0)

    idempotency_key = conn
    |> get_req_header("x-idempotency-key")
    |> Enum.at(0) || ""

    records = %{
      id: id,
      idempotency_key: idempotency_key,
      ip_address: conn.remote_ip |> Tuple.to_list |> Enum.join("."),
      request: get_request_data(conn)
    }
    |> Log.create
  end

  defp log(conn, :response) do
    conn
    |> get_resp_header("x-request-id")
    |> Enum.at(0)
    |> Log.update(%{api: get_api_data(conn),
                    consumer: get_consumer_data(conn),
                    response: get_response_data(conn),
                    latencies: get_latencies_data(conn),
                    status_code: conn.status
                    })
  end

  defp modify_headers_list([]), do: []
  defp modify_headers_list([{key, value}|t]), do: [%{key => value}] ++ modify_headers_list(t)

  defp get_json_string(conn, data_func) do
    conn
    |> data_func.()
    |> Poison.encode!
  end

  defp get_api_data(conn) do
    case conn.private.api_config do
      nil -> %{}
      _ -> conn.private.api_config
    end
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
