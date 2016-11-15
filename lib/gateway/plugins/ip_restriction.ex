defmodule Gateway.Plugins.IPRestriction do
  @moduledoc """
  [IP Restriction plugin](http://docs.annon.apiary.io/#reference/plugins/ip-restriction).

  It allows to white/black-list consumers by a IP addresses.
  Also you can use it in Consumer plugin settings overrides to limit IP's from which specific consumer
  can request your API.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "ip_restriction"

  import Gateway.Helpers.IP

  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema
  alias EView.Views.Error, as: ErrorView
  alias Gateway.Helpers.Response

  @doc false
  def call(%Plug.Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(%Plugin{} = plugin, %Plug.Conn{remote_ip: remote_ip} = conn) do
    if check_ip(plugin, ip_to_string(remote_ip)) do
      conn
    else
      "403.json"
      |> ErrorView.render(%{message: "You has been blocked from accessing this resource."})
      |> Response.send(conn, 403)
      |> Response.halt()
    end
  end
  defp execute(_, conn), do: conn

  defp check_ip(plugin, ip) do
    blacklisted = blacklisted?(plugin, ip)
    whitelisted = whitelisted?(plugin, ip)
    whitelisted || (whitelisted === nil && !blacklisted)
  end

  defp whitelisted?(%Plugin{settings: %{"ip_whitelist" => list}}, ip) do
    list
    |> Enum.any?(fn(item) -> ip_matches?(item, ip) end)
  end
  defp whitelisted?(_plugin, _ip), do: nil

  defp blacklisted?(%Plugin{settings: %{"ip_blacklist" => list}}, ip) do
    list
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
end
