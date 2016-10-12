defmodule Gateway.DB.Repo.Migrations.AddConsumersTable do
  use Ecto.Migration

  def change do
    create table(:consumers) do
      add :name, :string
      add :request, :map

      timestamps()
    end
  end
end
