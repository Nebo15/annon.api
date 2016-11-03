defmodule Gateway.Plugins.IPRestriction do
  @moduledoc """
  IP restriction plug.
  """
  import Gateway.HTTPHelpers.Response
  import Gateway.Helpers.IP
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APIModel

  def init(opts), do: opts

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> get_enabled()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{} = plugin, %Plug.Conn{remote_ip: remote_ip} = conn) do
    if check_ip(plugin, ip_to_string(remote_ip)) do
      conn
    else
      render_response(%{}, conn, 400)
    end
  end

  defp check_ip(plugin, ip) do
    blacklisted = blacklisted?(plugin, ip)
    whitelisted = whitelisted?(plugin, ip)
    whitelisted || (whitelisted === nil && !blacklisted)
  end

  defp whitelisted?(%Plugin{settings: %{"ip_whitelist" => list}}, ip) do
    list
    |> String.split(",")
    |> Enum.any?(fn(item) -> ip_matches?(item, ip) end)
  end
  defp whitelisted?(_plugin, _ip), do: nil

  defp blacklisted?(%Plugin{settings: %{"ip_blacklist" => list}}, ip) do
    list
    |> String.split(",")
    |> Enum.any?(fn(item) -> ip_matches?(item, ip) end)
  end
  defp blacklisted?(_plugin, _ip), do: nil

  defp ip_matches?(ip1, ip2) do
    ip2_list = String.split(ip2, ".")
    0 < ip1
    |> String.split(".")
    |> Enum.reduce_while(0, fn(item, i) ->
      case item !== "*" && item !== Enum.at(ip2_list, i) do
        true -> {:halt, -1}
        _    -> {:cont, i + 1}
      end
    end)
  end

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end

  defp filter_plugin(%Plugin{name: :ip_restriction, is_enabled: true}), do: true
  defp filter_plugin(_), do: false
end
