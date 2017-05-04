defmodule Annon.Cache.EtsAdapter do
  @moduledoc """
  Adapter to access cache using ETS.
  """
  import Ecto.Query

  alias Annon.Configuration.Repo
  alias Annon.Configuration.Schemas.API
  alias Annon.Configuration.Schemas.Plugin

  def find_api_by(scheme, host, port) do
    match_spec = %{
      request: %{
        scheme: scheme,
        port: port
      }
    }

    :config
    |> :ets.match_object({:_, match_spec})
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(fn(api) -> host == api.request.host || "*" == api.request.host end)
    |> Annon.Cache.FilterHelper.do_filter(host)
  end

  def warm_up do
    query =
      from a in API,
        join: Plugin,
        preload: [:plugins]

    apis =
      query
      |> Repo.all()
      |> Enum.map(fn api -> {{:api, api.id}, api} end)

    :ets.insert(:config, apis)
  end
end
