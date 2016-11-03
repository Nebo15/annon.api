defmodule Gateway.DB.Configs.Repo.Migrations.PluginsAddEnabled do
  use Ecto.Migration

  def change do
    alter table(:plugins) do
      add :is_enabled, :boolean
    end
  end
end
