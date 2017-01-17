defmodule Gateway.Plugins.UARestriction do
  @moduledoc """
  It allows to white/black-list consumers by user agent.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "ua_restriction"

  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema
  alias EView.Views.Error, as: ErrorView
  alias Gateway.Helpers.Response

  @doc false
  def call(%Plug.Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugin = plugins
    |> find_plugin_settings()

    validation_result = plugin
    |> validate_plugin_settings()

    plugin
    |> execute(conn, validation_result)
  end
  def call(conn, _), do: conn

  defp validate_plugin_settings(%Plugin{settings: settings}), do: validate_whitelist(settings)
  defp validate_plugin_settings(_), do: {:error}

  defp validate_whitelist(settings) do
    settings
    |> validate_list("whitelist")
    |> validate_blacklist(settings)
  end

  defp validate_blacklist({:error}, _settings), do: {:error}
  defp validate_blacklist({:ok}, settings) do
    settings
    |> validate_list("blacklist")
  end

  defp validate_list(settings, key) do
    settings
    |> Map.get(key)
    |> validate_regexp_list()
  end

  defp validate_regexp_list(nil), do: {:ok}
  defp validate_regexp_list(list) do
    case Enum.all?(list, fn item ->
      case Regex.compile(item) do
        {:ok, _} -> true
        _ -> false
      end
      end) do
      true -> {:ok}
      _ -> {:error}
    end
  end

  defp extract_user_agent(conn) do
    conn
    |> Plug.Conn.get_req_header("user-agent")
    |> Enum.at(0)
  end

  defp execute(_plugin, conn, {:error}), do: Response.send_validation_error(conn, [{"settings", "invalid"}])
  defp execute(%Plugin{} = plugin, conn, {:ok}) do
    if check_user_agent(plugin, extract_user_agent(conn)) do
      conn
    else
      "403.json"
      |> ErrorView.render(%{message: "You have been blocked from accessing this resource."})
      |> Response.send(conn, 403)
      |> Response.halt()
    end
  end
  defp execute(_, conn, {:ok}), do: conn

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
