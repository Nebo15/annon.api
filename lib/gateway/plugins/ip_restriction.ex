defmodule Gateway.Plugins.IPRestriction do
  @moduledoc """
  IP restriction plug
  """
  import Plug.Conn
  import Gateway.HTTPHelpers.Response
  import Gateway.Helpers.IP

  defp get_blacklist do
    []
  end

  defp is_blacklisted(ip) do
    blacklist = get_blacklist()
    Enum.any?(blacklist, fn(item) -> compare_ips(item, ip) end)
  end

  defp get_whitelist do
    []
  end

  defp is_whitelisted(ip) do
    whitelist = get_whitelist()
    Enum.any?(whitelist, fn(item) -> compare_ips(item, ip) end)
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

  defp check_ip(ip) do
    blacklisted = is_blacklisted ip
    whitelisted = is_whitelisted ip
    whitelisted || !blacklisted
  end

  def init(opts), do: opts

  def call(conn, _opts) do
    ip = ip_to_string conn.remote_ip
    allow = check_ip ip
    conn = register_before_send(conn, fn conn ->
      if allow,
        do: conn,
        else: with {code, body} <- render_response(%{}, 400, "blacklisted"), do: resp(conn, code, body)
    end)
    conn
  end
end
