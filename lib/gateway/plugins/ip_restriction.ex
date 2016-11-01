defmodule Gateway.Plugins.IPRestriction do
  @moduledoc """
  IP restriction plug
  """
  import Plug.Conn
  import Gateway.HTTPHelpers.Response
  import Gateway.Helpers.IP
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  defp get_plugin(%Plug.Conn{private: %{api_config: %{plugins: plugins}}}) do
    Enum.find(plugins, fn(plugin) -> plugin.name === :IPRestriction end)
  end
  defp get_plugin(_conn), do: %{}

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end

  defp filter_plugin(%Plugin{name: :IPRestriction, is_enabled: true}), do: true
  defp filter_plugin(_), do: false

  defp get_settings(nil), do: %{}
  defp get_settings(plugin), do: Map.get(plugin, :settings, %{})

  defp get_list(%Plugin{} = plugin, key), do: plugin |> get_settings() |> get_list(key)
  defp get_list(nil, _key), do: []
  defp get_list(settings, key), do: Map.get(settings, key, [])

  defp blacklisted?(plugin, ip) do
    plugin
    |> get_list("ip_blacklist")
    |> Enum.any?(fn(item) -> compare_ips(item, ip) end)
  end

  defp whitelisted?(%Plugin{} = plugin, ip), do: plugin |> get_list("ip_whitelist") |> whitelisted?(ip)
  defp whitelisted?([], _ip), do: nil
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

  defp check_ip(plugin, ip) do
    blacklisted = blacklisted?(plugin, ip)
    whitelisted = whitelisted?(plugin, ip)
    whitelisted || (whitelisted === nil && !blacklisted)
  end

  def init(opts), do: opts

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> get_enabled()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{} = plugin, conn) do
    ip = ip_to_string conn.remote_ip
    register_before_send(conn, fn conn ->
      allow = check_ip(plugin, ip)

      if allow do
        conn
      else
        with {code, body} <- render_response(%{}, 400, "blacklisted") do
          conn
          |> resp(code, body)
          |> halt()
        end
      end
    end)
  end
end
