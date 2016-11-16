defmodule Gateway.Plugins.Proxy do
  @moduledoc """
  [Proxy](http://docs.annon.apiary.io/#reference/plugins/proxy) - is a core plugin that
  sends incoming request to an upstream back-ends.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "proxy"

  import Gateway.Helpers.IP

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
    response = settings
    |> make_link(api_path, conn)
    |> do_request(conn, method)

    response.headers
    |> Enum.reduce(conn, fn
      {"x-request-id", _header_value}, conn ->
        conn
      {header_key, header_value}, conn ->
        conn |> Conn.put_resp_header(header_key, header_value)
    end)
    |> Conn.send_resp(response.status_code, response.body)
    |> Conn.halt
  end

  def do_request(link, conn, method) do
    # TODO: Make sure we also accept octet-stream header in
    #       conj. with form via content-disposition
    case Plug.Conn.get_req_header(conn, "content-type") do
      [content_type] ->
        if String.starts_with?(content_type, "multipart/form-data") do
          do_fileupload_request_cont(link, conn, method)
        else
          do_request_cont(link, conn, method)
        end
      [nil] ->
        do_request_cont(link, conn, method)
    end
  end

  def do_fileupload_request_cont(link, conn, method) do
    req_headers = [] # TODO: make sure we pass along all incoming request headers,
                     # except for

    {:ok, ref} = :hackney.request(method, link, req_headers, :stream_multipart, [])

    # TODO: walk through all body_params, and attach them?

    # Not possible to do right now. See: https://github.com/benoitc/hackney/issues/363

    Enum.each conn.body_params, fn {key, value} ->
      case value do
        %Plug.Upload{path: path} ->
          :ok = :hackney.send_multipart_body(ref, {:file, path})
      end
    end

    :ok = :hackney.send_multipart_body(ref, :eof)

    {:ok, status, headers, ref} = :hackney.start_response(ref)
    {:ok, body} = :hackney.body(ref)

    :hackney.close(ref)

    %{status_code: status, headers: headers, body: body}
  end

  defp put_thing({key, %Plug.Upload{} = upload}) do
    {:file, upload[:path], } # Explore additional headers from hackney as the third parameter here!
  end

  def do_request_cont(link, conn, method) do
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

  def put_additional_headers(headers, conn) do
    headers
    |> Kernel.++([%{"x-forwarded-for" => ip_to_string(conn.remote_ip)}])
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
