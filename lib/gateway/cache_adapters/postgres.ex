defmodule Gateway.CacheAdapters.Postgres do
  import Ecto.Query

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.API

  def find_api_by(scheme, host, port) do
    query = from a in API,
      where: fragment("request->'scheme' = ?", ^scheme),
      where: fragment("request->'host' = ?", ^host),
      where: fragment("request->'port' = ?", ^port),
      join: Gateway.DB.Schemas.Plugin,
      preload: [:plugins]

    Repo.all(query)
  end
end
