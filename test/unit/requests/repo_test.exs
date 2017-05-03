defmodule Annon.Requests.RepoTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Annon.Requests.Repo

  setup do
    %{config: [
      database: "db",
      username: "name",
      password: "pwd",
      hostname: "host",
      port: "port",
    ]}
  end

  test "REQUESTS_DATABASE_URL environment variable is overriding defaults", %{config: config} do
    System.put_env("REQUESTS_DATABASE_URL", "postgres://my_user:password@pghost:1234/db_name")
    on_exit(fn ->
      System.delete_env("REQUESTS_DATABASE_URL")
    end)

    assert {:ok, [
      username: "my_user",
      password: "password",
      database: "db_name",
      hostname: "pghost",
      port: 1234
    ]} = Repo.init(Repo, config)
  end

  test "raises when database name is not set", %{config: config} do
    assert_raise RuntimeError, "Set DB_NAME environment variable!", fn ->
      Repo.init(Repo, Keyword.delete(config, :database))
    end
  end

  test "raises when database username is not set", %{config: config} do
    assert_raise RuntimeError, "Set DB_USER environment variable!", fn ->
      Repo.init(Repo, Keyword.delete(config, :username))
    end
  end

  test "raises when database password is not set", %{config: config} do
    assert_raise RuntimeError, "Set DB_PASSWORD environment variable!", fn ->
      Repo.init(Repo, Keyword.delete(config, :password))
    end
  end

  test "raises when database host is not set", %{config: config} do
    assert_raise RuntimeError, "Set DB_HOST environment variable!", fn ->
      Repo.init(Repo, Keyword.delete(config, :hostname))
    end
  end

  test "raises when database port is not set", %{config: config} do
    assert_raise RuntimeError, "Set DB_PORT environment variable!", fn ->
      Repo.init(Repo, Keyword.delete(config, :port))
    end
  end
end
