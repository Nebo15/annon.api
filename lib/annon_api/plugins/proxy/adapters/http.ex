defmodule Annon.Plugins.Proxy.Adapters.HTTP do
  @doc """
  HTTP(s) requests adapter that sends body as-is via HTTPPoison.
  """
  alias Annon.Plugin.UpstreamRequest
  alias Plug.Conn

  def dispatch(%UpstreamRequest{} = upstream_request, %Conn{method: method} = conn) do
    upstream_url = UpstreamRequest.to_upstream_url!(upstream_request)

    case Conn.get_req_header(conn, "content-type") do
      [content_type | _] ->
        if String.starts_with?(content_type, "multipart/form-data") do
          do_fileupload_request_cont(upstream_url, upstream_request, conn, method)
        else
          do_request_cont(upstream_url, upstream_request, conn, method)
        end
      _ ->
        do_request_cont(upstream_url, upstream_request, conn, method)
    end
  end

  defp do_fileupload_request_cont(upstream_url, upstream_request, conn, _method) do
    req_headers =
      Enum.reject(upstream_request.headers, fn {k, _} ->
        String.downcase(k) in ["content-type", "content-disposition", "content-length", "host"]
      end)

    multipart = Annon.Plugins.Proxy.MultipartForm.reconstruct_using(conn.body_params)

    HTTPoison.post!(upstream_url, {:multipart, multipart}, req_headers)
  end

  defp do_request_cont(upstream_url, upstream_request, conn, method) do
    method = String.to_atom(method)
    body =
      conn
      |> Map.get(:body_params)
      |> Poison.encode!()

    timeout_opts = [connect_timeout: 30_000, recv_timeout: 30_000, timeout: 30_000]

    headers = Enum.reject(upstream_request.headers, fn {k, _} -> k == "host" end)

    case HTTPoison.request(method, upstream_url, body, headers, timeout_opts) do
      {:ok, response} ->
        response
      {:error, %{reason: reason}} ->
        %{
          status_code: 502,
          body: Annon.Helpers.Response.build_upstream_error(reason),
          headers: []
        }
    end
  end
end
