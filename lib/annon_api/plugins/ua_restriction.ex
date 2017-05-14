defmodule Annon.Plugins.UARestriction do
  @moduledoc """
  It allows to white/black-list consumers by user agent.

  TODO: refactor validation from this file and pre-compile patterns for reuse
  """
  use Annon.Plugin, plugin_name: :ua_restriction
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response
  require Logger

  defdelegate validate_settings(changeset), to: Annon.Plugins.UARestriction.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.UARestriction.SettingsValidator

  def execute(%Conn{} = conn, _request, settings) do
    with {:ok, user_agent} <- fetch_user_agent(conn),
         true <- check_user_agent(settings, user_agent) do
      conn
    else
      :error ->
        Logger.warn("Request does not contain User-Agent header, User Agent restrictions won't be applied")
        conn
      false ->
        render_forbidden(conn)
    end
  end

  defp fetch_user_agent(conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [] -> :error
      [user_agent | _] -> {:ok, user_agent}
    end
  end

  defp check_user_agent(settings, user_agent) do
    blacklisted = blacklisted?(settings, user_agent)
    whitelisted = whitelisted?(settings, user_agent)
    whitelisted || (whitelisted === nil && !blacklisted)
  end

  defp whitelisted?(%{"whitelist" => list}, user_agent),
    do: Enum.any?(list, &user_agent_matches?(&1, user_agent))
  defp whitelisted?(_plugin, _user_agent),
    do: nil

  defp blacklisted?(%{"blacklist" => list}, user_agent),
    do: Enum.any?(list, &user_agent_matches?(&1, user_agent))
  defp blacklisted?(_plugin, _user_agent),
    do: nil

  defp user_agent_matches?(regex, user_agent) do
    regex
    |> Regex.compile!()
    |> Regex.match?(user_agent)
  end

  def render_forbidden(conn) do
    "403.json"
    |> ErrorView.render(%{message: "You has been blocked from accessing this resource"})
    |> Response.send(conn, 403)
    |> Response.halt()
  end
end
