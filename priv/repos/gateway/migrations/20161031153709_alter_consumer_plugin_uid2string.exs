defmodule Gateway.DB.Repo.Migrations.AlterConsumerPluginUid2string do
  use Ecto.Migration

  def change do
    alter table(:consumer_plugin_settings) do
      remove :external_id
      add :external_id, :string
    end  
  end
end
