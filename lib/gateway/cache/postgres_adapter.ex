defmodule Gateway.Cache.PostgresAdapter do
  @moduledoc """
  Adapter to access cache using RDBMS.
  """
  import Ecto.Query

  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.API
  alias Gateway.DB.Schemas.Plugin

  def find_api_by(scheme, host, port) do
    query = from a in API,
      where: fragment("request->'scheme' = ?", ^scheme),
      where: fragment("request->>'host' IN (?, '*')", ^host),
      where: fragment("request->'port' = ?", ^port),
      join: Plugin,
      preload: [:plugins]

    query
    |> Repo.all()
    |> Gateway.Cache.FilterHelper.do_filter(host)
  end

  def warm_up, do: :nothing
end
