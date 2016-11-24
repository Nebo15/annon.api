defmodule Gateway.Plugins.APILoader do
  @moduledoc """
  This plugin should be first in plugs pipeline,
  because it's used to fetch all settings and decide which ones should be applied for current consumer request.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "api_loader"

  import Plug.Conn

  @doc false
  def call(conn, _opts), do: put_private(conn, :api_config, conn |> get_config)

  def get_config(conn) do
    scheme = normalize_scheme(conn.scheme)
    host = get_host(conn)
    port = conn.port

    apis = Gateway.CacheAdapters.ETS.find_api_by(scheme, host, port)

    apis
    |> Enum.map(&elem(&1, 1))
    |> find_matching_method(conn.method)
    |> find_matching_path(conn.request_path)
  end

  defp get_host(conn) do
    case get_req_header(conn, "x-host-override") do
      [] -> conn.host
      [override | _] -> override
    end
  end

  defp normalize_scheme(scheme) when is_atom(scheme), do: Atom.to_string(scheme)
  defp normalize_scheme(scheme), do: scheme

  def find_matching_method(apis, method) do
    apis
    |> Enum.filter(&Enum.member?(&1.request.methods, method))
  end

  def find_matching_path(apis, path) do
    apis
    |> Enum.filter(&String.starts_with?(path, &1.request.path))
    |> Enum.sort_by(&String.length(&1.request.path))
    |> Enum.reverse
    |> List.first
  end
end
