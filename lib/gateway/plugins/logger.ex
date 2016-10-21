defmodule Gateway.Plugins.Logger do
  @moduledoc """
  Request/response logger plug
  """
  import Gateway.Helpers.Cassandra
  import Plug.Conn

  def init(opts) do
    opts
  end

  defp get_body(conn, :request) do
    {:ok, body, _conn} = read_body(conn)
    body
  end

  defp get_body(conn, :response) do
    conn.resp_body
  end

  defp parse_header(headers, header_name) do
    headers = Enum.filter(headers, fn(header) -> elem(header, 0) === header_name end)
    result = with [header | _] <- headers, do: elem(header, 1)
    if result === [] do "" else result end
  end

  defp modify_headers_list([]), do: []
  defp modify_headers_list([{key, value}|t]), do: [%{key => value}] ++ modify_headers_list(t)

  defp get_json_string(conn, data_func) do
    conn
    |> data_func.()
    |> Poison.encode!
  end

  defp get_api_data(_conn) do
    %{}
  end

  defp get_consumer_data(_conn) do
    %{}
  end

  defp get_request_data(conn) do
    %{
      method: conn.method,
      uri: conn.request_path,
      query: conn.query_string,
      headers: modify_headers_list(conn.req_headers),
      body: get_body(conn, :request)
    }
  end

  defp get_response_data(conn) do
    %{
      status_code: conn.status,
      headers: modify_headers_list(conn.resp_headers),
      body: get_body(conn, :response)
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
    id = parse_header(conn.resp_headers, "x-request-id")
    idempotency_key = parse_header(conn.resp_headers, "x-idempotency-key")
    records = [%{
      id: id,
      idempotency_key: idempotency_key,
      ip_address: conn.remote_ip,
      request: get_json_string(conn, &get_request_data/1)
    }]
    execute_query(records, :insert_logs)
  end

  defp log(conn, :response) do
    id = parse_header(conn.resp_headers, "x-request-id")
    records = [%{
      id: id,
      api: get_json_string(conn, &get_api_data/1),
      consumer: get_json_string(conn, &get_consumer_data/1),
      response: get_json_string(conn, &get_response_data/1),
      latencies: get_json_string(conn, &get_latencies_data/1),
      status_code: conn.status
    }]
    execute_query(records, :update_logs)
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
