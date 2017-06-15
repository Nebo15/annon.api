defmodule Annon.Configuration.Repo do
  @moduledoc """
  Main repository for DB that stores configuration.

  This database doesn't need to have high performance, since all data is
  [fetched once and cached in Annon](http://docs.annon.apiary.io/#introduction/general-features/caching-and-perfomance).
  """

  use Ecto.Repo, otp_app: :annon_api
  use Ecto.Paging.Repo

  @doc """
  Dynamically loads the repository configuration from the environment variables.
  """
  def init(_, config) do
    url = System.get_env("CONFIGURATION_DATABASE_URL")
    config = if url, do: Keyword.merge(config, Ecto.Repo.Supervisor.parse_url(url)), else: Confex.process_env(config)

    unless config[:database] do
      raise "Set DB_NAME environment variable!"
    end

    unless config[:username] do
      raise "Set DB_USER environment variable!"
    end

    unless config[:password] do
      raise "Set DB_PASSWORD environment variable!"
    end

    unless config[:hostname] do
      raise "Set DB_HOST environment variable!"
    end

    unless config[:port] do
      raise "Set DB_PORT environment variable!"
    end

    {:ok, config}
  end
end
