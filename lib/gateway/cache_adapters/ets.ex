defmodule Gateway.CacheAdapters.ETS do
  def find_api_by(conn) do
    match_spec = %{
      request: %{
        host: get_host(conn),
        port: conn.port,
        scheme: normalize_scheme(conn.scheme)
      }
    }

    :config
    |> :ets.match_object({:_, match_spec})
    |> Enum.map(&elem(&1, 1))
    |> find_matching_method(conn.method)
    |> find_matching_path(conn.request_path)
  end

  defp get_host(conn) do
    case Plug.Conn.get_req_header(conn, "x-host-override") do
      [] -> conn.host
      [override | _] -> override
    end
  end

  defp normalize_scheme(scheme) when is_atom(scheme), do: Atom.to_string(scheme)
  defp normalize_scheme(scheme), do: scheme

  defp find_matching_method(apis, method) do
    apis
    |> Enum.filter(&Enum.member?(&1.request.methods, method))
  end

  defp find_matching_path(apis, path) do
    apis
    |> Enum.filter(&String.starts_with?(path, &1.request.path))
    |> Enum.sort_by(&String.length(&1.request.path))
    |> Enum.reverse
    |> List.first
  end
end
