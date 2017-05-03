defmodule Annon.Requests.Repo.Migrations.AlterTablesTimestamps do
  use Ecto.Migration

  def change do
    alter table(:logs) do
      remove :inserted_at
      remove :updated_at

      timestamps(type: :utc_datetime)
    end
  end
end
