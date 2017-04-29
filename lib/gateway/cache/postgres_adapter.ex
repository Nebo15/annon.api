defmodule Annon.Cache.PostgresAdapter do
  @moduledoc """
  Adapter to access cache using RDBMS.
  """
  import Ecto.Query

  alias Annon.DB.Configs.Repo
  alias Annon.DB.Schemas.API
  alias Annon.DB.Schemas.Plugin

  def find_api_by(scheme, host, port) do
    query = from a in API,
      where: fragment("request->'scheme' = ?", ^scheme),
      where: fragment("request->>'host' IN (?, '*')", ^host),
      where: fragment("request->'port' = ?", ^port),
      join: Plugin,
      preload: [:plugins]

    query
    |> Repo.all()
    |> Annon.Cache.FilterHelper.do_filter(host)
  end

  def warm_up, do: :nothing
end
