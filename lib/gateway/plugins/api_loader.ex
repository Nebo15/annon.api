defmodule Gateway.Plugins.APILoader do
  @moduledoc """
  Plugin which get all configuration by endpoint.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "api_loader"

  import Plug.Conn

  def call(conn, _opts), do: put_private(conn, :api_config, conn |> get_config)

  def get_config(conn) do
    match_spec = %{
      request: %{
        host: conn.host,
        method: conn.method,
        port: conn.port,
        scheme: normalize_scheme(conn.scheme)
      }
    }

    :config
    |> :ets.match_object({:_, match_spec})
    |> find_matching_path(conn.request_path)
  end

  def normalize_scheme(scheme) when is_atom(scheme), do: Atom.to_string(scheme)
  def normalize_scheme(scheme), do: scheme

  def find_matching_path(apis, path) do
    apis
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(&String.starts_with?(path, &1.request.path))
    |> Enum.sort_by(&String.length(&1.request.path))
    |> Enum.reverse
    |> List.first
  end
end
