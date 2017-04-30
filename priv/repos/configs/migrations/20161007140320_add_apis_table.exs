defmodule Annon.DB.Configs.Repo.Migrations.AddApisTable do
  use Ecto.Migration

  def change do
    create table(:apis) do
      add :name, :string
      add :request, :map

      timestamps()
    end

    create unique_index(:apis, [:name])

    columns = [
      "(request->>'host')",
      "(request->>'port')",
      "(request->>'path')",
      "(request->>'scheme')",
      "(request->>'methods')"
    ]

    create unique_index(:apis, columns, uniq: true, name: "api_unique_request_index")
  end
end
