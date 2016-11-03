defmodule Gateway.Helpers.Plugin do
  @moduledoc """
  Helper for most of plugins.
  """
  alias Gateway.DB.Schemas.Plugin

  @doc """
  Find plugin settings in `plugins` list. Returns `nil` if plugin is not found.
  """
  def find_plugin_settings(plugins, plugin_name) when is_list(plugins) and is_atom(plugin_name) do
    plugins
    |> Enum.find(&filter_plugin(&1, plugin_name))
  end

  defp filter_plugin(%Plugin{name: plugin_name, is_enabled: true}, plugin_name), do: true
  defp filter_plugin(_, _), do: false
end
