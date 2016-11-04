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
        scheme: normalize_scheme(conn.scheme),
        path: conn.request_path
      }
    }

    case :ets.match_object(:config, {:_, match_spec}) do
      [{_, api} | _] -> api
      _ -> nil
    end
  end

  def normalize_scheme(scheme) when is_atom(scheme), do: Atom.to_string(scheme)
  def normalize_scheme(scheme), do: scheme
end
