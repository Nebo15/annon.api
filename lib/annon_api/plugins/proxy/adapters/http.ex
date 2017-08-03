defmodule Annon.Plugins.Proxy.Adapters.HTTP do
  @moduledoc """
  HTTP(s) requests adapter that sends body as-is via HTTPPoison.
  """
  alias Annon.Plugin.UpstreamRequest
  alias Plug.Conn
  require Logger

  @stream_opts [
    length: :infinity,      # Read whole response
    read_length: 1_049_600, # in 1 Mb chunks
    read_timeout: 15_000    # with 15 seconds timeout between chunks
  ]

  @buffer_opts [
    connect_timeout: 30_000,
    recv_timeout: 30_000,
    timeout: 30_000
  ]

  def dispatch(%UpstreamRequest{} = upstream_request, %Conn{body_params: %Plug.Conn.Unfetched{}} = conn) do
    upstream_url = UpstreamRequest.to_upstream_url!(upstream_request)
    method = String.to_atom(conn.method)

    with {:ok, client_ref} <- :hackney.request(method, upstream_url, upstream_request.headers, :stream, []),
         {:ok, client_ref, conn} <- stream_request_body(client_ref, upstream_request, conn),
         %Conn{} = conn <- stream_response_body(client_ref, conn) do
      {:ok, conn}
    else
      {:error, term} ->
        {:ok, Conn.send_resp(conn, 502, Annon.Helpers.Response.build_upstream_error(to_string(term)))}
    end
  end

  def dispatch(%UpstreamRequest{} = upstream_request, %Conn{method: method} = conn) do
    upstream_url = UpstreamRequest.to_upstream_url!(upstream_request)
    method = String.to_atom(method)

    body =
      conn
      |> Map.get(:body_params)
      |> Poison.encode!()

    case HTTPoison.request(method, upstream_url, body, upstream_request.headers, @buffer_opts) do
      {:ok, %{headers: resp_headers, status_code: resp_status_code, body: resp_body}} ->
        conn =
          conn
          |> put_response_headers(resp_headers)
          |> Conn.send_resp(resp_status_code, resp_body)

        {:ok, conn}
      {:error, %{reason: reason}} ->
        conn = Conn.send_resp(conn, 502, Annon.Helpers.Response.build_upstream_error(reason))
        {:ok, conn}
    end
  end

  defp stream_request_body(client_ref, upstream_request, conn) do
    case Conn.read_body(conn, @stream_opts) do
      {:ok, body, conn} ->
        :hackney.send_body(client_ref, body)
        {:ok, client_ref, conn}

      {:more, body, conn} ->
        :hackney.send_body(client_ref, body)
        stream_request_body(client_ref, upstream_request, conn)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp stream_response_body(client_ref, conn) do
    case :hackney.start_response(client_ref) do
      {:ok, status_code, headers} ->
        conn
        |> put_response_headers(headers)
        |> Conn.send_resp(status_code, "")

      {:ok, status_code, headers, client_ref} ->
        conn
        |> put_response_headers(headers)
        |> Conn.send_chunked(status_code)
        |> stream_response_chunk(client_ref)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp put_response_headers(conn, headers) do
    Enum.reduce(headers, conn, fn
      {"x-request-id", _header_value}, conn ->
        conn
      {header_key, header_value}, conn ->
        Conn.put_resp_header(conn, String.downcase(header_key), header_value)
    end)
  end

  defp stream_response_chunk(conn, client_ref) do
    case :hackney.stream_body(client_ref) do
      {:ok, body} ->
        {:ok, conn} = Conn.chunk(conn, body)
        stream_response_chunk(conn, client_ref)

      :done ->
        conn

      {:error, reason} ->
        {:error, reason}
    end
  end
end
