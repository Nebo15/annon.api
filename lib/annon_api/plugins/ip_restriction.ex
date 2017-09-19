defmodule Annon.Plugins.IPRestriction do
  @moduledoc """
  [IP Restriction plugin](http://docs.annon.apiary.io/#reference/plugins/ip-restriction).

  It allows to white/black-list consumers by a IP addresses.
  Also you can use it in Consumer plugin settings overrides to limit IP's from which specific consumer
  can request your API.
  """
  use Annon.Plugin, plugin_name: :ip_restriction
  import Annon.Helpers.IP
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response

  defdelegate validate_settings(changeset), to: Annon.Plugins.IPRestriction.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.IPRestriction.SettingsValidator

  def execute(%Conn{remote_ip: remote_ip} = conn, _request, settings) do
    if check_ip(settings, ip_to_string(remote_ip)) do
      conn
    else
      "403.json"
      |> ErrorView.render(%{message: "You has been blocked from accessing this resource"})
      |> Response.send(conn, 403)
      |> Response.halt()
    end
  end

  defp check_ip(plugin, ip) do
    blacklisted = blacklisted?(plugin, ip)
    whitelisted = whitelisted?(plugin, ip)
    whitelisted || (whitelisted === nil && !blacklisted)
  end

  defp whitelisted?(%{"whitelist" => list}, ip),
    do: ip_listed?(list, ip)
  defp whitelisted?(_plugin, _ip),
    do: nil

  defp blacklisted?(%{"blacklist" => list}, ip),
    do: ip_listed?(list, ip)
  defp blacklisted?(_plugin, _ip),
    do: nil

  defp ip_listed?(list, ip) do
    Enum.any? list, fn listed_ip ->
      case CIDR.parse(listed_ip) do
        %CIDR{} = cidr ->
          CIDR.match!(cidr, ip)
        {:error, _} ->
          ip_matches?(listed_ip, ip)
      end
    end
  end

  defp ip_matches?(ip1, ip2) do
    ip2_list = String.split(ip2, ".")

    matches_count =
      ip1
      |> String.split(".")
      |> Enum.reduce_while(0, fn(item, i) ->
        case item !== "*" && item !== Enum.at(ip2_list, i) do
          true -> {:halt, -1}
          _    -> {:cont, i + 1}
        end
      end)

    0 < matches_count
  end
end
