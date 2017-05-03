defmodule Annon.ReleaseTasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:

      annon_api/bin/annon_api command Elixir.Annon.ReleaseTasks migrate!
  """
  alias Ecto.Migrator

  @start_apps [
    :logger_json,
    :postgrex,
    :ecto
  ]

  @otp_app :annon_api

  @repos [
    Annon.Configuration.Repo,
    Annon.Requests.Repo
  ]

  def migrate! do
    IO.puts "Loading #{@otp_app}.."
    # Load the code for apps, but don't start it
    :ok = Application.load(@otp_app)

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for annon_api
    IO.puts "Starting repos.."
    Enum.each(@repos, &(&1.start_link(pool_size: 1)))

    # Run migrations
    run_migrations_for(@otp_app)

    # Run the seed script if it exists
    seed_script = seed_path(@otp_app)
    if File.exists?(seed_script) do
      IO.puts "Running seed script for app #{@otp_app}.."
      Code.eval_file(seed_script)
    end

    # Signal shutdown
    IO.puts "Success!"
    :init.stop()
  end

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"
    Enum.each(@repos, &run_repo_migrations(app, &1))
  end

  defp run_repo_migrations(app, repo) do
    Migrator.run(repo, migrations_path(app, repo), :up, all: true)
  end

  defp migrations_path(app, repo) do
    priv_path =
      app
      |> Application.get_env(repo)
      |> Keyword.get(:priv)

    case priv_path do
      nil -> Path.join([priv_dir(app), "repos", String.downcase(Atom.to_string(repo)), "migrations"])
      "priv/" <> path -> Path.join([priv_dir(app), path, "migrations"])
      full_path -> full_path
    end
  end

  defp seed_path(app),
    do: Path.join([priv_dir(app), "repos", "seeds.exs"])

  def priv_dir(app),
    do: :code.priv_dir(app)
end
