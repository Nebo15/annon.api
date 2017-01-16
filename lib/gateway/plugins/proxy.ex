defmodule Gateway.Plugins.Proxy do
  @moduledoc """
  [Proxy](http://docs.annon.apiary.io/#reference/plugins/proxy) - is a core plugin that
  sends incoming request to an upstream back-ends.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "proxy"

  import Gateway.Helpers.IP
  import Gateway.Helpers.Latency

  alias Plug.Conn
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema

  @doc false
  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins, request: %{path: api_path}}}} = conn, _opts)
    when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(api_path, conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, _, conn), do: conn
  defp execute(%Plugin{settings: settings} = plugin, api_path, conn) do
    conn = plugin
    |> get_additional_headers()
    |> put_request_id(conn)
    |> put_additional_headers(conn)
    |> skip_filtered_headers(settings)

    settings
    |> do_proxy(api_path, conn)
  end

  defp do_proxy(settings, api_path, %Conn{method: method} = conn) do
    req_start_time = get_time()

    response = settings
    |> make_link(api_path, conn)
    |> do_request(conn, method)

    conn = write_latency(conn, :latencies_upstream, req_start_time)

    response.headers
    |> Enum.reduce(conn, fn
      {"x-request-id", _header_value}, conn ->
        conn
      {header_key, header_value}, conn ->
        conn |> Conn.put_resp_header(String.downcase(header_key), header_value)
    end)
    |> Conn.send_resp(response.status_code, response.body)
    |> Conn.halt
  end

  def do_request(link, conn, method) do
    case Plug.Conn.get_req_header(conn, "content-type") do
      [content_type] ->
        if String.starts_with?(content_type, "multipart/form-data") do
          do_fileupload_request_cont(link, conn, method)
        else
          do_request_cont(link, conn, method)
        end
      _ ->
        do_request_cont(link, conn, method)
    end
  end

  defp do_fileupload_request_cont(link, conn, _method) do
    req_headers = Enum.reject(conn.req_headers, fn {k, _} ->
      String.downcase(k) in ["content-type", "content-disposition", "content-length"]
    end)

    multipart = Gateway.Plugins.Proxy.MultipartForm.reconstruct_using(conn.body_params)

    HTTPoison.post!(link, {:multipart, multipart}, req_headers)
  end

  defp do_request_cont(link, conn, method) do
    body = conn
    |> Map.get(:body_params)
    |> Poison.encode!()

    method
    |> String.to_atom
    |> HTTPoison.request!(link, body, Map.get(conn, :req_headers))
  end

  def make_link(proxy, api_path, conn) do
    proxy
    |> put_scheme(conn)
    |> put_host(proxy)
    |> put_port(proxy)
    |> put_path(proxy, api_path, conn)
    |> put_query(proxy, conn)
  end

  defp put_request_id(headers, conn) do
    id = conn
    |> Conn.get_resp_header("x-request-id")
    |> Enum.at(0)

    [%{"x-request-id" => id}] ++ headers
  end

  defp put_x_forwarded_for_header(headers, conn), do: headers ++ [%{"x-forwarded-for" => ip_to_string(conn.remote_ip)}]

  defp put_x_consumer_scopes_header(headers, %Conn{private: %{scopes: nil}}), do: headers
  defp put_x_consumer_scopes_header(headers, %Conn{private: %{scopes: scopes}}) do
    headers ++ [%{"x-consumer-scopes" => Enum.join(scopes, " ")}]
  end
  defp put_x_consumer_scopes_header(headers, _), do: headers

  defp put_x_consumer_id_header(headers, %Conn{private: %{consumer_id: nil}}), do: headers
  defp put_x_consumer_id_header(headers, %Conn{private: %{consumer_id: consumer_id}}) do
    headers ++ [%{"x-consumer-id" => consumer_id}]
  end
  defp put_x_consumer_id_header(headers, _), do: headers

  defp remove_protected_headers(conn) do
    :gateway
    |> Confex.get(:protected_headers)
    |> Enum.reduce(conn, fn(header, conn) -> Conn.put_req_header(conn, header, "") end)
  end

  def put_additional_headers(headers, conn) do
    conn = remove_protected_headers(conn)
    headers
    |> put_x_forwarded_for_header(conn)
    |> put_x_consumer_scopes_header(conn)
    |> put_x_consumer_id_header(conn)
    |> Enum.reduce(conn, fn(header, conn) ->
      with {k, v} <- header |> Enum.at(0), do: Conn.put_req_header(conn, k, v)
    end)
  end

  defp get_additional_headers(%Plugin{settings: %{"additional_headers" => headers}}), do: headers
  defp get_additional_headers(_), do: []

  def skip_filtered_headers(conn, %{"strip_headers" => true, "headers_to_strip" => headers}) do
    Enum.reduce(headers, conn, &Plug.Conn.delete_req_header(&2, &1))
  end
  def skip_filtered_headers(conn, _plugin), do: conn

  defp put_scheme(%{"scheme" => scheme}, _conn), do: scheme <> "://"
  defp put_scheme(_, %Conn{scheme: scheme}), do: Atom.to_string(scheme) <> "://"

  defp put_host(pr, %{"host" => host}), do: pr <> host
  defp put_host(pr, %{}), do: pr

  defp put_port(pr, %{"port" => port}) when is_number(port), do: pr |> put_port(%{"port" => Integer.to_string(port)})
  defp put_port(pr, %{"port" => port}), do: pr <> ":" <> port
  defp put_port(pr, %{}), do: pr

  defp put_path(pr, %{"strip_api_path" => true, "path" => "/"}, api_path, %Conn{request_path: request_path}),
    do: pr <> String.trim_leading(request_path, api_path)

  defp put_path(pr, %{"strip_api_path" => true, "path" => proxy_path}, api_path, %Conn{request_path: request_path}),
    do: pr <> proxy_path <> String.trim_leading(request_path, api_path)

  defp put_path(pr, %{"strip_api_path" => true}, api_path, %Conn{request_path: request_path}),
    do: pr <> String.trim_leading(request_path, api_path)

  defp put_path(pr, %{"path" => "/"}, _api_path, %Conn{request_path: request_path}),
    do: pr <> request_path

  defp put_path(pr, %{"path" => proxy_path}, _api_path, %Conn{request_path: request_path}),
    do: pr <> proxy_path <> request_path

  defp put_path(pr, _proxy_path, _api_path, %Conn{request_path: request_path}),
    do: pr <> request_path

  defp put_query(pr, _, %Conn{query_string: ""}), do: pr
  defp put_query(pr, _, %Conn{query_string: query_string}), do: pr <> "?" <> query_string
end
