defmodule Annon.ReleaseTasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:

      annon_api/bin/annon_api command Elixir.Annon.ReleaseTasks migrate!
  """
  alias Ecto.Migrator

  @otp_app :annon_api
  @start_apps [:logger_json, :postgrex, :ecto]

  def migrate do
    init(@otp_app, @start_apps)
    run_migrations_for(@otp_app)
    stop()
  end

  defp init(app, start_apps) do
    IO.puts "Loading app.."
    :ok = Application.load(app)

    IO.puts "Starting dependencies.."
    Enum.each(start_apps, &Application.ensure_all_started/1)

    IO.puts "Starting repos.."
    app
    |> Application.get_env(:ecto_repos, [])
    |> Enum.each(&(&1.start_link(pool_size: 1)))
  end

  defp stop do
    IO.puts "Success!"
    :init.stop()
  end

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"

    app
    |> Application.get_env(:ecto_repos, [])
    |> Enum.each(&Migrator.run(&1, migrations_path(app, &1), :up, all: true))
  end

  defp migrations_path(app, repo) do
    "priv/" <> rel_path =
      app
      |> Application.get_env(repo)
      |> Keyword.fetch!(:priv)

    path = priv_dir(app, [rel_path, "migrations"])
    IO.puts "- for repo #{Atom.to_string(repo)} from path #{path}"
    path
  end

  defp priv_dir(app, path) when is_list(path) do
    case :code.priv_dir(app) do
      priv_path when is_binary(priv_path) or is_list(priv_path) ->
        Path.join([priv_path] ++ path)

      {:error, :bad_name} ->
        raise ArgumentError, "unknown application `#{inspect app}`"
    end
  end
end
