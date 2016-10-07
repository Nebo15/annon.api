defmodule Gateway.DB.Repo.Migrations.AddApisTable do
  use Ecto.Migration

  def change do
    create table(:apis) do
      add :name, :string
      add :scheme, :string
      add :host, :string
      add :port, :string
      add :path, :string

      timestamps()
    end
  end
end
