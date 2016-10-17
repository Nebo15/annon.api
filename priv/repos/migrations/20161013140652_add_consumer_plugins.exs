defmodule Gateway.DB.Repo.Migrations.AddConsumerPluginSettings do
  use Ecto.Migration

  def change do
    create table(:consumer_plugin_settings) do
      add :external_id, :string
      add :plugin_id, :integer
      add :settings, :map

      timestamps()
    end

    index_name = :consumer_plugin_settings_external_id_plugin_id

    create unique_index(:consumer_plugin_settings, [:external_id, :plugin_id], name: index_name)
  end
end
