defmodule Annon.Configuration.Repo.Migrations.RemoveFieldFromLogs do
  use Ecto.Migration

  def up do
    alter table(:logs) do
      remove :consumer
    end
  end

  def down do
    alter table(:logs) do
      add :consumer, :map
    end
  end
end
