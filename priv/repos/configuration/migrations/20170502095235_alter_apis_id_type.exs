defmodule Annon.Configuration.Repo.Migrations.AlterApisIdType do
  use Ecto.Migration

  def change do
    alter table(:apis) do
      remove :id
      add :id, :uuid, primary_key: true
    end

    alter table(:plugins) do
      remove :api_id
      add :api_id, :uuid, null: false
    end

    create index(:plugins, [:api_id, :name], unique: true)
  end
end
