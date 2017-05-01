defmodule Annon.Configuration.Repo.Migrations.ConsumerPluginsAddIsEnabled do
  use Ecto.Migration

  def change do
    alter table(:consumer_plugin_settings) do
      add :is_enabled, :boolean
    end
  end
end
