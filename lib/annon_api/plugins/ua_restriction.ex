defmodule Annon.Plugins.UARestriction do
  @moduledoc """
  It allows to white/black-list consumers by user agent.

  TODO: refactor validation from this file and pre-compile patterns for reuse
  """
  use Annon.Plugin, plugin_name: "ua_restriction"
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response

  defdelegate validate_settings(changeset), to: Annon.Plugins.UARestriction.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.UARestriction.SettingsValidator

  def execute(%Conn{} = conn, _request, settings) do
    settings
    |> check_user_agent(get_user_agent(conn, ""))
    |> process_check_result(conn)
  end

  defp get_user_agent(conn, default) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [] -> default
      [user_agent|_] -> user_agent
    end
  end

  defp process_check_result(true, conn), do: conn
  defp process_check_result(_, conn) do
    "403.json"
    |> ErrorView.render(%{message: "You have been blocked from accessing this resource."})
    |> Response.send(conn, 403)
    |> Response.halt()
  end

  defp check_user_agent(settings, user_agent) do
    blacklisted = blacklisted?(settings, user_agent)
    whitelisted = whitelisted?(settings, user_agent)
    whitelisted || (whitelisted === nil && !blacklisted)
  end

  defp whitelisted?(%{"whitelist" => list}, user_agent) do
    list
    |> Enum.any?(fn(item) -> user_agent_matches?(item, user_agent) end)
  end
  defp whitelisted?(_plugin, _user_agent), do: nil

  defp blacklisted?(%{"blacklist" => list}, user_agent) do
    list
    |> Enum.any?(fn(item) -> user_agent_matches?(item, user_agent) end)
  end
  defp blacklisted?(_plugin, _user_agent), do: nil

  defp user_agent_matches?(regex, user_agent) do
    regex
    |> Regex.compile!()
    |> Regex.match?(user_agent)
  end
end
