defmodule Gateway.Cache.EtsAdapter do
  @moduledoc """
  Adapter to access cache using ETS.
  """
  import Ecto.Query

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.API
  alias Gateway.DB.Schemas.Plugin

  def find_api_by(scheme, host, port) do
    match_spec = %{
      request: %{
        scheme: scheme,
        host: host,
        port: port
      }
    }

    :config
    |> :ets.match_object({:_, match_spec})
    |> Enum.map(&elem(&1, 1))
  end

  def warm_up do
    query = from a in API,
            join: Plugin,
            preload: [:plugins]

    apis =
      query
      |> Repo.all()
      |> Enum.map(fn api -> {{:api, api.id}, api} end)

    :ets.insert(:config, apis)
  end
end
