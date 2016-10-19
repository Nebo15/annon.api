defmodule Gateway.Logger do
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

  defp get_header_name(header) do
    {header_name, _} = header
    header_name
  end

  defp get_header_value(header) do
    {_, header_value} = header
    header_value
  end

  defp parse_header(headers, header_name) do
    headers = Enum.filter(headers, fn(header) -> get_header_name(header) === header_name end)
    result = with [header | _] <- headers, do: get_header_value(header)
    if result === [] do "" else result end
  end

  defp modify_headers_list([]), do: []
  defp modify_headers_list([{key, value}|t]), do: [%{key => value}] ++ modify_headers_list(t)

  defp get_json_string(conn, data_func) do
    conn
    |> data_func.()
    |> Poison.encode
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
    {:ok, request_string} = get_json_string(conn, &get_request_data/1)
    records = [
      %{id: id, idempotency_key: idempotency_key, ip_address: conn.remote_ip, request: request_string}
    ]
    execute_query(records, :insert_logs)
  end

  defp log(conn, :response) do
    id = parse_header(conn.resp_headers, "x-request-id")
    {:ok, response_string} = get_json_string(conn, &get_response_data/1)
    {:ok, latencies_string} = get_json_string(conn, &get_latencies_data/1)
    records = [
      %{id: id, response: response_string, latencies: latencies_string, status_code: conn.status}
    ]
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
