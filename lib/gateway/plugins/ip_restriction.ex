defmodule Gateway.Plugins.IPRestriction do
  @moduledoc """
  IP restriction plug
  """
  import Plug.Conn
  import Gateway.HTTPHelpers.Response
  import Gateway.Helpers.IP

  defp get_plugins(%Plug.Conn{private: %{api_config: %{plugins: plugins}}}), do: plugins
  defp get_plugins(_conn), do: []

  defp get_plugin_settings(conn) do
    conn.private.api_config
    |> get_plugins()
    |> Enum.find(fn(plugin) -> plugin.name === :IPRestriction end)
  end

  defp get_list(%Plug.Conn{} = conn, key), do: conn |> get_plugin_settings() |> get_list(key)
  defp get_list(nil, _key), do: []
  defp get_list(settings, key), do: Map.get(settings, key, [])

  defp blacklisted?(conn, ip) do
    conn
    |> get_list(:ip_blacklist)
    |> Enum.any?(fn(item) -> compare_ips(item, ip) end)
  end

  defp whitelisted?(%Plug.Conn{} = conn, ip), do: conn |> get_list(:ip_whitelist) |> whitelisted?(ip)
  defp whitelisted?([], _ip), do: true
  defp whitelisted?(whitelist, ip), do: Enum.any?(whitelist, fn(item) -> compare_ips(item, ip) end)

  defp compare_ips(ip1, ip2) do
    ip1_list = String.split(ip1, ".")
    ip2_list = String.split(ip2, ".")
    i = Enum.reduce(ip1_list, 0, fn(item, i) ->
      if i !== -1 do
        if item !== "*" && item !== Enum.at(ip2_list, i)
        do i = -1
        else i = i + 1 end
      else i = -1 end
    end)
    i > 0
  end

  defp check_ip(conn, ip) do
    blacklisted = blacklisted?(conn, ip)
    whitelisted = whitelisted?(conn, ip)
    whitelisted || !blacklisted
  end

  def init(opts), do: opts

  def call(conn, _opts) do
    ip = ip_to_string conn.remote_ip
    conn = register_before_send(conn, fn conn ->
      allow = check_ip(conn, ip)
      if allow,
        do: conn,
        else: with {code, body} <- render_response(%{}, 400, "blacklisted"), do: resp(conn, code, body)
    end)
    conn
  end
end
