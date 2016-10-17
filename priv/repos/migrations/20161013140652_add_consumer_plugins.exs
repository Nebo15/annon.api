defmodule Gateway.DB.Repo.Migrations.AddConsumerPluginSettings do
  use Ecto.Migration

  def change do
    create table(:consumer_plugin_settings) do
      add :consumer_id, :string
      add :plugin_id, :integer
      add :settings, :map

      timestamps()
    end
  end
end
