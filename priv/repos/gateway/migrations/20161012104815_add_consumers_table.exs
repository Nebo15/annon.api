defmodule Gateway.DB.Configs.Repo.Migrations.AddConsumersTable do
  use Ecto.Migration

  def change do
    create table(:consumers, primary_key: false) do
      add :external_id, :uuid
      add :metadata, :map

      timestamps()
    end
  end
end
