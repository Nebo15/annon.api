defmodule Annon.Plugin.PipelinePlug do
  @moduledoc """
  This module inject Plugins pipeline into Plug.Router.
  """
  alias Plug.Conn
  alias Annon.Plugin
  alias Annon.Plugin.Request
  alias Annon.Plugin.UpstreamRequest
  alias Annon.Configuration.Matcher

  @plugins Application.fetch_env!(:annon_api, :plugins)

  def init(_opts) do
    :annon_api
    |> Application.get_env(:plugin_pipeline)
    |> Keyword.fetch!(:default_features)
  end

  def call(%Conn{} = conn, default_features) do
    api = resolve_api(conn)
    plugins = resolve_plugins(api)

    request =
      api
      |> build_request(plugins)
      |> prepare_plugins()
      |> Plugin.update_feature_requirements(default_features)

    conn
    |> put_upstream_request()
    |> execute_plugins(request)
  end

  defp resolve_api(conn) do
    %Conn{method: method, port: port, request_path: path} = conn
    scheme = Atom.to_string(conn.scheme)
    host = get_host(conn)

    case Matcher.match_request(scheme, method, host, port, path) do
      {:ok, api} ->
        api
      {:error, :not_found} ->
        nil
    end
  end

  defp get_host(conn) do
    case Conn.get_req_header(conn, "x-host-override") do
      [] ->
        conn.host
      [override | _] ->
        override
    end
  end

  defp build_request(api, plugins) do
    start_time = System.monotonic_time()
    %Request{
      start_time: start_time,
      api: api,
      plugins: plugins
    }
  end

  defp put_upstream_request(conn) do
    Conn.assign(conn, :upstream_request, %UpstreamRequest{})
  end

  defp resolve_plugins(nil) do
    Enum.reduce(@plugins, [], fn {name, opts}, acc ->
      if Keyword.get(opts, :system?, false),
        do: acc ++ [get_system_plugin(name, opts)],
      else: acc
    end)
  end
  defp resolve_plugins(%{plugins: api_plugins}) do
    Enum.reduce(@plugins, [], fn {name, opts}, acc ->
      plugin =
        if Keyword.get(opts, :system?, false),
            do: get_system_plugin(name, opts),
          else: get_plugin(name, api_plugins, opts)

      if plugin.is_enabled,
          do: acc ++ [plugin],
        else: acc
    end)
  end

  defp get_system_plugin(name, opts) do
    %Annon.Plugin{
      name: name,
      module: Keyword.fetch!(opts, :module),
      is_enabled: true,
      settings: %{},
      deps: Keyword.get(opts, :deps, []),
      features: Keyword.get(opts, :features, []),
      system?: true
    }
  end

  defp get_plugin(name, api_plugins, opts) do
    api_plugin = Enum.find(api_plugins, fn %{name: string_name} -> name == String.to_atom(string_name) end)
    is_enabled? = not is_nil(api_plugin)
    settings = if is_enabled?, do: api_plugin.settings, else: %{}

    %Annon.Plugin{
      name: name,
      module: Keyword.fetch!(opts, :module),
      is_enabled: is_enabled?,
      settings: settings,
      deps: Keyword.get(opts, :deps, []),
      features: Keyword.get(opts, :features, []),
      system?: false
    }
  end

  defp prepare_plugins(%{plugins: plugins} = request) when is_list(plugins) do
    Enum.reduce(plugins, request, fn %{module: module}, request ->
      module.prepare(request)
    end)
  end

  defp execute_plugins(conn, %{plugins: plugins} = request) when is_list(plugins) do
    Enum.reduce(plugins, conn, fn
      _plugin, %Conn{halted: true} = conn ->
        conn
      %{module: module, settings: settings}, conn ->
        module.execute(conn, request, settings)
    end)
  end
end
