defmodule Annon.Configuration.Repo.Migrations.DropPluginsId do
  use Ecto.Migration

  def change do
    alter table(:plugins) do
      remove :id
    end
  end
end
