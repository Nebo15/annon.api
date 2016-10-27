defmodule Gateway.Plugins.Logger do
  @moduledoc """
  Request/response logger plug
  """
  import Gateway.Helpers.Cassandra
  import Plug.Conn
  alias Gateway.Logger.DB.Repo
  alias Gateway.Logger.DB.Models.LogRecord

  def init(opts) do
    opts
  end

  defp modify_headers_list([]), do: []
  defp modify_headers_list([{key, value}|t]), do: [%{key => value}] ++ modify_headers_list(t)

  defp get_json_string(conn, data_func) do
    conn
    |> data_func.()
    |> Poison.encode!
  end

  defp get_api_data(_conn), do: %{}

  defp get_consumer_data(_conn), do: %{}

  defp get_request_data(conn) do
    %{
      method: conn.method,
      uri: conn.request_path,
      query: conn.query_string,
      headers: modify_headers_list(conn.req_headers),
      body: conn.body_params
    }
  end

  defp get_response_data(conn) do
    %{
      status_code: conn.status,
      headers: modify_headers_list(conn.resp_headers),
      body: conn.resp_body
    }
  end

  defp get_latencies_data(_conn) do
    %{
      gateway: "",
      upstream: "",
      client_request: ""
    }
  end

  defp log(conn, :request) do
    id = conn
    |> get_resp_header("x-request-id")
    |> Enum.at(0) || ""

    idempotency_key = conn
    |> get_req_header("x-idempotency-key")
    |> Enum.at(0) || ""

    records = %{
      id: id,
      idempotency_key: idempotency_key,
      ip_address: conn.remote_ip |> Tuple.to_list |> Enum.join("."),
      request: get_request_data(conn) |> prepare_params
    }

    records
    |> LogRecord.create
    #execute_query(records, :insert_logs)
    
  end

  defp get_key(key) when is_binary(key), do: String.to_atom(key)
  defp get_key(key) when is_atom(key), do: key
  defp prepare_params(params), do: for {key, val} <- params, into: %{}, do: {get_key(key), val}

  defp log(conn, :response) do
    id = conn
    |> get_resp_header("x-request-id")
    |> Enum.at(0) || ""
    records = [%{
      id: id,
      api: get_json_string(conn, &get_api_data/1),
      consumer: get_json_string(conn, &get_consumer_data/1),
      response: get_json_string(conn, &get_response_data/1),
      latencies: get_json_string(conn, &get_latencies_data/1),
      status_code: conn.status
    }]
    #execute_query(records, :update_logs)
  end

  def call(conn, _opts) do
    log(conn, :request)
    conn = register_before_send(conn, fn conn ->
      log(conn, :response)
      conn
    end)
    conn
  end
end
