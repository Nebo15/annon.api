defmodule Gateway.CacheAdapters.ETS do
  def find_api_by(scheme, host, port) do
    match_spec = %{
      request: %{
        scheme: scheme,
        host: host,
        port: port
      }
    }

    :ets.match_object(:config, {:_, match_spec})
  end
end
