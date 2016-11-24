defmodule Gateway.Cache.PostgresAdapter do
  import Ecto.Query

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.API
  alias Gateway.DB.Schemas.Plugin

  def find_api_by(scheme, host, port) do
    query = from a in API,
      where: fragment("request->'scheme' = ?", ^scheme),
      where: fragment("request->'host' = ?", ^host),
      where: fragment("request->'port' = ?", ^port),
      join: Plugin,
      preload: [:plugins]

    Repo.all(query)
  end
end
