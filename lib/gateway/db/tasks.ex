defmodule :gateway_tasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:
      ./bin/$APP_NAME command "gateway_tasks" migrate!
  """
  require Logger

  @otp_app :gateway
  @repos Confex.get(@otp_app, :ecto_repos)
  @default_repos_path Path.join(["priv", "repos"])

  def migrate! do
    load_app()

    @repos
    |> Enum.each(fn repo ->
      migrations_path = get_migrations_path(@otp_app, repo)

      Logger.info("Running migrations for #{@otp_app} repo #{inspect repo}. Migrations path: #{migrations_path}")

      repo
      |> start_repo
      |> Ecto.Migrator.run(migrations_path, :up, all: true)
    end)

    System.halt(0)
    :init.stop()
  end

  defp get_migrations_path(otp_app, repo) do
    conf_path = otp_app
    |> Confex.get(repo)
    |> Keyword.get(:priv)

    Path.join([conf_path || @default_repos_path, "migrations"])
  end

  defp start_repo(repo) do
    repo.start_link()
    repo
  end

  defp load_app do
    start_applications([:logger, :postgrex, :ecto])
    :ok = Application.load(:gateway)
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {_ , _message} = Application.ensure_all_started(app)
    end)
  end
end
