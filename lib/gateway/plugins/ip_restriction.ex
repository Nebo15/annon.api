defmodule Gateway.Plugins.IPRestriction do
  @moduledoc """
  IP restriction plug
  """
  import Plug.Conn
  import Gateway.HTTPHelpers.Response
  import Gateway.Helpers.IP

  defp get_plugin_settings(conn) do
    api_config = conn.private.api_config || %{}
    plugins = Map.get(api_config, :plugins, [])
    settings = for plugin <- plugins, plugin.name === :IPRestriction, do: plugin.settings
    List.first(settings)
  end

  defp get_list(conn, key) do
    settings = get_plugin_settings(conn) || %{}
    Map.get(settings, key, [])
  end

  defp is_blacklisted(conn, ip) do
    blacklist = get_list(conn, :ip_blacklist)
    Enum.any?(blacklist, fn(item) -> compare_ips(item, ip) end)
  end

  defp is_whitelisted(conn, ip) do
    whitelist = get_list(conn, :ip_whitelist)
    if Enum.empty?(whitelist),
    do: true,
    else: Enum.any?(whitelist, fn(item) -> compare_ips(item, ip) end)
  end

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
    blacklisted = is_blacklisted(conn, ip)
    whitelisted = is_whitelisted(conn, ip)
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
