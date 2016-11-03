defmodule :gateway_tasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.
  Example:
      ./bin/$APP_NAME command "tr_db_tasks" migrate!
  """

  @otp_app :gateway
  @repos Confex.get(@otp_app, :ecto_repos)
  @default_migrations_dir Path.join(["priv", "repos", "migrations"]

  def migrate! do
    load_app()

    @repos
    |> Enum.each(fn repo ->
      migrations_dir = Confex.get(@otp_app, repo)[:priv] || @default_migrations_dir

      repo
      |> start_repo
      |> Ecto.Migrator.run(migrations_dir, :up, all: true)
    end)

    System.halt(0)
    :init.stop()
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
