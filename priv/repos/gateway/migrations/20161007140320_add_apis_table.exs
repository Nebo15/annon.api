defmodule Gateway.DB.Configs.Repo.Migrations.AddApisTable do
  use Ecto.Migration

  def change do
    create table(:apis) do
      add :name, :string
      add :request, :map

      timestamps()
    end
  end
end
