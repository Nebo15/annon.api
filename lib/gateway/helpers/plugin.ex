defmodule Gateway.Helpers.Plugin do
  @moduledoc """
  This helper provides abstract interface to define plugin.

  Example:

      use Gateway.Helpers.Plugin,
        plugin_name: "my_plugin"

  It will add
    * `init/1` settings required by Plug behavior, that will pass opts to `init/2` methods.
    * `find_plugin_settings/1` method that allows to find plugin settings and make sure that it's enabled.
  """
  alias Gateway.DB.Schemas.Plugin, as: PluginSchema

  defmacro __using__(compile_time_opts) do
    quote bind_quoted: [compile_time_opts: compile_time_opts], location: :keep do
      require Logger
      import Gateway.Helpers.Plugin
      alias Gateway.DB.Schemas.Plugin

      unless compile_time_opts[:plugin_name] do
        throw "You need to pass `:plugin_name` when using Gateway.Helpers.Plugin"
      end

      @plugin_name compile_time_opts[:plugin_name]

      # This is general function that we don't use since configs are resolved in run-time
      def init(opts), do: opts

      def find_plugin_settings(plugins) when is_list(plugins) do
        plugins
        |> Enum.find(&filter_plugin/1)
      end

      defp filter_plugin(%PluginSchema{name: plugin_name, is_enabled: true}) when plugin_name == @plugin_name, do: true
      defp filter_plugin(_), do: false
    end
  end

  @doc """
  Find plugin settings in `plugins` list. Returns `nil` if plugin is not found.
  """
  @callback find_plugin_settings([PluginSchema.t]) :: nil | PluginSchema.t
end
