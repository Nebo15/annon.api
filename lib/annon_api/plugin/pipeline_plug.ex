defmodule Annon.Plugin.PipelinePlug do
  @moduledoc """
  This module inject Plugins pipeline into Plug.Router.
  """
  alias Plug.Conn
  alias Annon.Plugin.Request
  alias Annon.Plugin.FeatureRequirements
  alias Annon.Plugin.UpstreamRequest
  alias Annon.Configuration.Matcher

  @plugins Application.fetch_env!(:annon_api, :plugins)

  def init(opts),
    do: opts

  def call(%Conn{} = conn, _opts) do
    api = resolve_api(conn)
    plugins = resolve_plugins(api)

    # TMP
    conn = Conn.assign(conn, :request_start_time, System.monotonic_time())
    conn = Conn.put_private(conn, :api_config, api)

    request =
      conn
      |> build_request(api, plugins)
      |> prepare_plugins()

    conn
    |> put_upstream_request()
    |> execute_plugins(request)
  end

  defp resolve_api(conn) do
    scheme = normalize_scheme(conn.scheme)
    method = conn.method
    host = get_host(conn)
    port = conn.port
    path = conn.request_path

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

  defp normalize_scheme(scheme) when is_atom(scheme),
    do: Atom.to_string(scheme)
  defp normalize_scheme(scheme) when is_binary(scheme),
    do: scheme

  defp build_request(conn, api, plugins) do
    start_time = System.monotonic_time()
    %Request{
      start_time: start_time,
      conn: conn,
      feature_requirements: %FeatureRequirements{},
      api: api,
      plugins: plugins
    }
  end

  defp put_upstream_request(conn),
    do: Conn.assign(conn, :upstream_request, %UpstreamRequest{})

  defp resolve_plugins(nil) do
    Enum.reduce(@plugins, [], fn {name, opts}, acc ->
      if Keyword.get(opts, :system?, false) do
        acc ++ [%Annon.Plugin{
          name: name,
          module: Keyword.fetch!(opts, :module),
          is_enabled: true,
          settings: %{},
          deps: Keyword.get(opts, :deps, []),
          features: Keyword.get(opts, :features, []),
          system?: true
        }]
      else
        acc
      end
    end)
  end
  defp resolve_plugins(api) do
    api_plugins = Map.get(api, :plugins, [])

    Enum.reduce(@plugins, [], fn {name, opts}, acc ->
      plugin =
        if Keyword.get(opts, :system?, false) do
          %Annon.Plugin{
            name: name,
            module: Keyword.fetch!(opts, :module),
            is_enabled: true,
            settings: %{},
            deps: Keyword.get(opts, :deps, []),
            features: Keyword.get(opts, :features, []),
            system?: true
          }
        else
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

      if plugin.is_enabled, do: acc ++ [plugin], else: acc
    end)
  end

  defp prepare_plugins(%{plugins: plugins} = request) when is_list(plugins) do
    Enum.reduce(plugins, request, fn %{module: module}, request ->
      module.prepare(request)
    end)
  end

  defp execute_plugins(conn, %{plugins: plugins} = request) when is_list(plugins) do
    Enum.reduce(plugins, conn, fn %{module: module, settings: settings}, conn ->
      module.execute(conn, request, settings)
    end)
  end
end
