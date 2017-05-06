defmodule Annon.Plugins.UARestriction do
  @moduledoc """
  It allows to white/black-list consumers by user agent.

  TODO: refactor validation from this file and pre-compile patterns for reuse
  """
  use Annon.Plugin,
    plugin_name: "ua_restriction"

  alias Annon.Configuration.Schemas.Plugin
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response

  @doc """
  Settings validator delegate.
  """
  defdelegate validate_settings(changeset), to: Annon.Plugins.UARestriction.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.UARestriction.SettingsValidator

  @doc false
  def call(%Plug.Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugin = find_plugin_settings(plugins)
    validation_result = validate_plugin_settings(plugin)

    plugin
    |> do_execute(conn, validation_result)
  end
  def call(conn, _), do: conn

  defp validate_plugin_settings(%Plugin{settings: settings}), do: validate_whitelist(settings)
  defp validate_plugin_settings(_), do: :ok

  defp validate_whitelist(settings) do
    with :ok <- validate_list(settings, "whitelist"),
         :ok <- validate_list(settings, "blacklist"),
     do: :ok
  end

  defp validate_list(settings, key) do
    settings
    |> Map.get(key)
    |> validate_regexp_list()
  end

  defp validate_regexp_list(nil), do: :ok
  defp validate_regexp_list(list) do
    case Enum.all?(list, fn item -> elem(Regex.compile(item), 0) == :ok end) do
      true -> :ok
      _ -> :error
    end
  end

  defp extract_user_agent(conn) do
    conn
    |> Plug.Conn.get_req_header("user-agent")
    |> Enum.at(0)
  end

  defp do_execute(_plugin, conn, :error), do: Response.send_validation_error(conn, [{"invalid", "settings"}])
  defp do_execute(%Plugin{} = plugin, conn, :ok) do
    plugin
    |> check_user_agent(extract_user_agent(conn))
    |> process_check_result(conn)
  end
  defp do_execute(_, conn, :ok), do: conn

  defp process_check_result(true, conn), do: conn
  defp process_check_result(_, conn) do
    "403.json"
    |> ErrorView.render(%{message: "You have been blocked from accessing this resource."})
    |> Response.send(conn, 403)
    |> Response.halt()
  end

  defp check_user_agent(plugin, user_agent) do
    blacklisted = blacklisted?(plugin, user_agent)
    whitelisted = whitelisted?(plugin, user_agent)
    whitelisted || (whitelisted === nil && !blacklisted)
  end

  defp whitelisted?(%Plugin{settings: %{"whitelist" => list}}, user_agent) do
    list
    |> Enum.any?(fn(item) -> user_agent_matches?(item, user_agent) end)
  end
  defp whitelisted?(_plugin, _user_agent), do: nil

  defp blacklisted?(%Plugin{settings: %{"blacklist" => list}}, user_agent) do
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
