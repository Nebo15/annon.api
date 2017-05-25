defmodule Annon.Configuration.CacheAdapters.ETS do
  @moduledoc """
  Adapter to access cache using ETS.
  """
  @behaviour Annon.Configuration.CacheAdapter
  alias Annon.Configuration.API

  def init(opts) do
    table_name = Keyword.fetch!(opts, :cache_space)
    :ets.new(table_name, [:ordered_set, :public, :named_table, read_concurrency: true])
    config_change(opts)
    :ok
  end

  def match_request(scheme, method, host, port, path, opts) do
    table_name = Keyword.fetch!(opts, :cache_space)

    match_spec = %{
      request: %{
        scheme: scheme,
        port: port
      }
    }

    apis =
      table_name
      |> :ets.match_object({:_, match_spec, :_, :_})
      |> filter_by_method(method)
      |> filter_by_host(host)
      |> filter_by_path(path)

    case apis do
      [] ->
        {:error, :not_found}
      [{_, api, _, _}|_] ->
        {:ok, api}
    end
  end

  def config_change(opts) do
    table_name = Keyword.fetch!(opts, :cache_space)

    objects = Enum.map(API.dump_apis(), fn api ->
      {{:api, api.id}, api, compile_host_regex(api.request.host), compile_path_regex(api.request.path)}
    end)

    case objects do
      [] ->
        :ok
      objects when is_list(objects) ->
        true = :ets.insert(table_name, objects)
        :ok
    end
  end

  defp filter_by_method(apis, method) do
    Enum.filter(apis, fn({_, api, _, _}) ->
      method in api.request.methods
    end)
  end

  defp compile_host_regex(host) do
    host_pattern =
        host
        |> Regex.escape()
        |> String.replace("%", ".*")
        |> String.replace("_", ".{1}")

    Regex.compile!("^#{host_pattern}$")
  end

  defp filter_by_host(apis, host) do
    Enum.filter(apis, fn({_, _, host_regex, _}) ->
      Regex.match?(host_regex, host)
    end)
  end

  defp compile_path_regex(path) do
    path_pattern =
      path
      |> Regex.escape()
      |> String.replace("%", ".*")
      |> String.replace("_", ".{1}")

    Regex.compile!("^#{path_pattern}")
  end

  defp filter_by_path(apis, path) do
    Enum.filter(apis, fn({_, _, _, path_regex}) ->
      Regex.match?(path_regex, path)
    end)
  end
end
