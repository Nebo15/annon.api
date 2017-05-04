defmodule Annon.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Annon.DataCase
      alias Annon.Configuration.Repo, as: ConfigurationRepo
      alias Annon.Requests.Repo, as: RequestsRepo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Annon.Configuration.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Annon.Requests.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Annon.Configuration.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(Annon.Requests.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  Helper for returning list of errors in a changeset.

  ## Examples

  Given a User schema that lists `:name` as a required field and validates
  `:password` to be safe, it would return:

      iex> changeset_errors(%Changeset{})
      [password: "is unsafe", name: "is blank"]

  You could then write your assertion like:

      assert {:password, "is unsafe"} in changeset_errors(%Changeset{})
  """
  def changeset_errors(changeset) do
    changeset.errors
  end
end
