defmodule Gateway.Plugins.Proxy do
  @moduledoc """
  Plugin which validates request based on ex_json_schema
  See more https://github.com/jonasschmidt/ex_json_schema
  """
  import Plug.Conn
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  def init(opts), do: opts

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> get_enabled()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{} = plugin, conn) do
    conn = plugin
    |> get_additional_headers
    |> add_additional_headers(conn)

    plugin
    |> get_settings()
    # TODO: check variables
    |> do_proxy(conn)
  end

  defp do_proxy(%{proxy: proxy}, %Plug.Conn{method: method} = conn) do
    response = proxy
    |> make_link(conn)
    |> do_request(conn, method)
    |> get_response

    conn |> send_resp(response.status_code, response.body) |> halt
  end

  def do_request(link, conn, method) do
    body = conn
    |> Map.get(:body_params)
    |> Poison.encode!()

    method
    |> String.to_atom
    |> HTTPoison.request!(link, body, Map.get(conn, :req_headers))
    |> get_response
  end

  def get_response(%HTTPoison.Response{} = response), do: response

  def make_link(proxy, conn) do
    proxy
    |> get_scheme(conn)
    |> get_host(proxy)
    |> get_port(proxy)
    |> get_path(proxy, conn)
  end

  defp add_additional_headers(headers, conn) do
    for {key, value} <- headers, do: put_req_header(conn, key, value)
    conn
  end

  defp get_additional_headers(%Plugin{settings: %{"additional_headers" => headers}}), do: headers
  defp get_additional_headers(_), do: []

  defp get_scheme(%{"scheme" => scheme}, _conn), do: scheme <> "://"
  defp get_scheme(_, %Plug.Conn{scheme: scheme}), do: Atom.to_string(scheme) <> "://"

  defp get_host(pr, %{"host" => host}), do: pr <> host
  defp get_host(pr, %{}), do: pr

  defp get_port(pr, %{"port" => port}) when is_number(port), do: pr |> get_port(%{"port" => Integer.to_string(port)})
  defp get_port(pr, %{"port" => port}), do: pr <> ":" <> port
  defp get_port(pr, %{}), do: pr

  defp get_path(pr, %{"path" => path}, _conn), do: pr <> path
  defp get_path(pr, %{}, %Plug.Conn{request_path: path}), do: pr <> path

  defp get_settings(%Plugin{settings: %{"proxy_to" => proxy}}), do: %{proxy: Poison.decode!(proxy)}
  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end
  defp filter_plugin(%Plugin{name: :Proxy, is_enabled: true}), do: true
  defp filter_plugin(_), do: false

end
