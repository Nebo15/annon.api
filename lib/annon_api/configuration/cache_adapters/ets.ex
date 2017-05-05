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
      |> :ets.match_object({:_, match_spec, :_})
      |> filter_by_method(method)
      |> filter_by_host(host)
      |> filter_by_path(path)

    case apis do
      [] ->
        {:error, :not_found}
      [{_, api, _}|_] ->
        {:ok, api}
    end
  end

  def config_change(opts) do
    table_name = Keyword.fetch!(opts, :cache_space)

    objects = Enum.map(API.dump_apis(), fn api ->
      host_pattern =
        api.request.host
        |> Regex.escape()
        |> String.replace("%", ".*")

      host_regex = Regex.compile!("^#{host_pattern}$")

      {{:api, api.id}, api, host_regex}
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
    Enum.filter(apis, fn({_, api, _}) ->
      method in api.request.methods
    end)
  end

  defp filter_by_host(apis, host) do
    Enum.filter(apis, fn({_, _, host_regex}) ->
      Regex.match?(host_regex, host)
    end)
  end

  defp filter_by_path(apis, path) do
    Enum.filter(apis, fn({_, api, _}) ->
      String.starts_with?(path, api.request.path)
    end)
  end
end
