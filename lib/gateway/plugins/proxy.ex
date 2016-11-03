defmodule Gateway.Plugins.Proxy do
  @moduledoc """
  Plugin which validates request based on ex_json_schema
  See more https://github.com/jonasschmidt/ex_json_schema
  """
  import Plug.Conn
  import Gateway.Helpers.IP
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
  defp execute(%Plugin{settings: settings} = plugin, conn) do
    conn = plugin
    |> get_additional_headers()
    |> add_additional_headers(conn)

    settings
    # TODO: check variables
    |> do_proxy(conn)
  end

  defp do_proxy(settings, %Plug.Conn{method: method} = conn) do
    response = settings
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
    |> put_scheme(conn)
    |> put_host(proxy)
    |> put_port(proxy)
    |> put_path(proxy, conn)
  end

  def add_additional_headers(headers, conn) do
    headers
    |> Kernel.++([%{"x-forwarded-for" => ip_to_string(conn.remote_ip)}])
    |> Enum.reduce(conn, fn(header, conn) -> with {k, v} <- header |> Enum.at(0), do: put_req_header(conn, k, v) end)
  end

  defp get_additional_headers(%Plugin{settings: %{"additional_headers" => headers}}), do: headers
  defp get_additional_headers(_), do: []

  defp put_scheme(%{"scheme" => scheme}, _conn), do: scheme <> "://"
  defp put_scheme(_, %Plug.Conn{scheme: scheme}), do: Atom.to_string(scheme) <> "://"

  defp put_host(pr, %{"host" => host}), do: pr <> host
  defp put_host(pr, %{}), do: pr

  defp put_port(pr, %{"port" => port}) when is_number(port), do: pr |> put_port(%{"port" => Integer.to_string(port)})
  defp put_port(pr, %{"port" => port}), do: pr <> ":" <> port
  defp put_port(pr, %{}), do: pr

  defp put_path(pr, %{"path" => path}, _conn), do: pr <> path
  defp put_path(pr, %{}, %Plug.Conn{request_path: path}), do: pr <> path

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end
  defp filter_plugin(%Plugin{name: :proxy, is_enabled: true}), do: true
  defp filter_plugin(_), do: false
end
