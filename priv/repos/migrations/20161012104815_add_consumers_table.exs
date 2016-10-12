defmodule Gateway.DB.Repo.Migrations.AddConsumersTable do
  use Ecto.Migration

  def change do
    create table(:consumers) do
      add :external_id, :string
      add :metadata, :map

      timestamps()
    end
  end
end
