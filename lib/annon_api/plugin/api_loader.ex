defmodule Annon.Plugin.APILoader do
  @moduledoc """
  This plugin should be first in plugs pipeline,
  because it's used to fetch all settings and decide which ones should be applied for current consumer request.
  """
  use Annon.Plugin,
    plugin_name: "api_loader"

  import Plug.Conn
  alias Annon.Configuration.Matcher

  @doc false
  def call(conn, _opts),
    do: put_private(conn, :api_config, find_api(conn))

  def find_api(conn) do
    scheme = normalize_scheme(conn.scheme)
    method = conn.method
    host = get_host(conn)
    port = conn.port
    path = conn.request_path

    case Matcher.match_request(scheme, method, host, port, path) do
      {:ok, api} -> api
      {:error, :not_found} -> nil
    end
  end

  defp get_host(conn) do
    case get_req_header(conn, "x-host-override") do
      [] -> conn.host
      [override | _] -> override
    end
  end

  defp normalize_scheme(scheme) when is_atom(scheme),
    do: Atom.to_string(scheme)
  defp normalize_scheme(scheme) when is_binary(scheme),
    do: scheme
end
