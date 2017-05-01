defmodule Annon.Configuration.Repo.Migrations.CleanupConsumers do
  use Ecto.Migration

  def up do
    drop table(:consumers)
    drop table(:consumer_plugin_settings)
  end

  def down do
    create table(:consumers, primary_key: false) do
      add :external_id, :uuid
      add :metadata, :map

      timestamps()
    end

    create table(:consumer_plugin_settings) do
      add :external_id, :uuid
      add :plugin_id, :integer
      add :settings, :map

      timestamps()
    end
  end
end
