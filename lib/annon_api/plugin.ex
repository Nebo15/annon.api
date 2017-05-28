defmodule Annon.Plugin do
  @moduledoc """
  This helper provides abstract interface to define plugin.

  Example:

      use Annon.Plugin,
        plugin_name: :my_plugin
  """
  alias Annon.Plugin.Request

  defstruct name: nil, module: nil, is_enabled: nil, settings: nil, deps: [], features: [], system?: false

  defmacro __using__(compile_time_opts) do
    quote bind_quoted: [compile_time_opts: compile_time_opts], location: :keep do
      import Annon.Plugin
      alias Annon.Plugin.Request
      alias Plug.Conn

      @behaviour Annon.Plugin

      unless compile_time_opts[:plugin_name] do
        throw "You need to pass `:plugin_name` when using Annon.Plugin"
      end

      @plugin_features compile_time_opts |> Keyword.fetch!(:plugin_name) |> get_plugin_features()

      @doc """
      Loads Plugin features from application configuration and modifies request features.
      """
      if @plugin_features == [] do
        def prepare(%Request{} = request),
          do: request
      else
        def prepare(%Request{} = request),
          do: update_feature_requirements(request, @plugin_features)
      end

      defoverridable [prepare: 1]
    end
  end

  @doc """
  Returns list of processing pipeline features that Plugin requires to work properly.
  """
  def get_plugin_features(plugin_name) when is_atom(plugin_name) do
    :annon_api
    |> Application.get_env(:plugins)
    |> Keyword.fetch!(plugin_name)
    |> Keyword.get(:features, [])
  end

  @doc """
  Updates `Annon.Plugin.Request` structure by raising flag on features in `features` list.
  """
  def update_feature_requirements(%Request{} = request, features) do
    feature_requirements =
      Enum.reduce(features, request.feature_requirements, fn feature, requirements ->
        Map.put(requirements, feature, true)
      end)

    %{request | feature_requirements: feature_requirements}
  end

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
                    plugin_settings :: %Annon.Configuration.Schemas.Plugin{}) :: %Annon.Plugin.Request{}

  @doc """
  Validates Plugin settings.
  """
  @callback validate_settings(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t

  @doc """
  Validates JSON Schema that can be used to validate Plugin settings.
  """
  @callback settings_validation_schema() :: Map.t
end
