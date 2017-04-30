defmodule Annon.DB.Configs.Repo.Migrations.Plugin do
  use Ecto.Migration

  def change do
    create table(:plugins) do
      add :api_id, :integer
      add :name, :string, size: 128
      add :is_enabled, :boolean
      add :settings, :map

      timestamps()
    end

    create index(:plugins, [:api_id, :name], unique: true)
  end
end
