defmodule Annon.Requests.Repo do
  @moduledoc """
  This repo is used to store request and responses.

  We recommend database with low write latency,
  because it will have up to 2 writes for each API call that is going trough Annon.

  Also, if Idempotency plug is enabled and `X-Idempotency-Key: <key>` header is sent by a consumer,
  you can expect an additional read request.
  """
  use Ecto.Repo, otp_app: :annon_api
  use Ecto.Paging.Repo

  @doc """
  Dynamically loads the repository configuration from the environment variables.
  """
  def init(_, config) do
    url = System.get_env("REQUESTS_DATABASE_URL")
    config =
      if url,
        do: Keyword.merge(config, Ecto.Repo.Supervisor.parse_url(url)),
      else: Confex.Resolver.resolve!(config)

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
