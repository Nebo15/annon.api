defmodule Gateway.DB.Repo.Migrations.Plugin do
  use Ecto.Migration

  def change do
    create table(:plugins) do
      add :api_id, :integer
      add :name, :string, size: 128
      add :settings, :map

      timestamps()
    end
  end
end
