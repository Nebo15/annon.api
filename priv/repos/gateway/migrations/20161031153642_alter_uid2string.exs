defmodule Gateway.DB.Configs.Repo.Migrations.AlterUid2string do
  use Ecto.Migration

  def change do
    alter table(:consumers) do
      remove :external_id
      add :external_id, :string
    end

    alter table(:consumer_plugin_settings) do
      remove :external_id
      add :external_id, :string
    end
  end
end
