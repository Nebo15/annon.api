defmodule Annon.Configuration.Repo.Migrations.AlterTablesTimestamps do
  use Ecto.Migration

  def change do
    alter table(:apis) do
      remove :inserted_at
      remove :updated_at

      timestamps(type: :utc_datetime)
    end

    alter table(:plugins) do
      remove :inserted_at
      remove :updated_at

      timestamps(type: :utc_datetime)
    end
  end
end
