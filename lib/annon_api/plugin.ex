defmodule Annon.Plugin do
  @moduledoc """
  This helper provides abstract interface to define plugin.

  Example:

      use Annon.Plugin,
        plugin_name: "my_plugin"

  It will add
    * `init/1` settings required by Plug behavior, that will pass opts to `init/2` methods.
    * `find_plugin_settings/1` method that allows to find plugin settings and make sure that it's enabled.
  """
  alias Annon.Configuration.Schemas.Plugin, as: PluginSchema
  alias Annon.Plugin.Request

  defmacro __using__(compile_time_opts) do
    quote bind_quoted: [compile_time_opts: compile_time_opts], location: :keep do
      import Annon.Plugin
      alias Annon.Plugin.Request
      alias Plug.Conn

      @behaviour Annon.Plugin

      unless compile_time_opts[:plugin_name] do
        throw "You need to pass `:plugin_name` when using Annon.Plugin"
      end

      @plugin_name compile_time_opts |> Keyword.fetch!(:plugin_name) |> String.to_atom()
      @plugin_info :annon_api |> Application.get_env(:plugins) |> Keyword.fetch!(@plugin_name)
      @plugin_features @plugin_info |> Keyword.get(:features, []) |> Enum.map(&({&1, true})) |> Enum.into(%{})

      @doc """
      Loads Plugin features from application configuration and modifies request features.
      """
      if @plugin_features == [] do
        def prepare(%Request{} = request),
          do: request
      else
        def prepare(%Request{} = request) do
          feature_requirements =
            Enum.reduce(@plugin_features, request.feature_requirements, fn feature, requirements ->
              Map.put(requirements, feature, true)
            end)

          %{request | feature_requirements: feature_requirements}
        end
      end
    end
  end

  defstruct name: nil, module: nil, is_enabled: nil, settings: nil, deps: [], features: [], system?: false

  @doc """
  Initializes Plugin.

  Receives `Annon.Plugin.Request` structure and returns it, which allows Plugin to:

    - Remove itself from execution pipeline if it should be disabled. (Eg. plugin that it depends on is not enabled.)
    - Set required execution features. (Eg. if it wants log writes to be consistent.)

  Connection MUST NOT be changed in a preparation pipeline.
  """
  @callback prepare(plugin_request :: %Annon.Plugin.Request{}) :: %Annon.Plugin.Request{}

  @doc """
  Executes Plugin.

  Receives `Annon.Plugin.Request` structure, which allows Plugin to:

    - Set properties for upstream request (in `conn.assigns.upstream_request`).
    - Modify connection if this feature was enabled.

  """
  @callback execute(conn :: Plug.Conn.t,
                    plugin_request :: %Annon.Plugin.Request{},
                    plugin_settings :: %PluginSchema{}) :: %Annon.Plugin.Request{}

  @doc """
  Validates Plugin settings.
  """
  @callback validate_settings(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t

  @doc """
  Validates JSON Schema that can be used to validate Plugin settings.
  """
  @callback settings_validation_schema() :: Map.t
end
