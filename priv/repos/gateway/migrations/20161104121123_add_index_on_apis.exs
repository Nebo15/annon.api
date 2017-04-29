defmodule Annon.DB.Repo.Migrations.AddIndexOnApis do
  use Ecto.Migration

  def change do
    columns = [
      "(request->>'host')",
      "(request->>'port')",
      "(request->>'path')",
      "(request->>'scheme')",
      "(request->>'method')"
    ]
    create unique_index(:apis, columns, uniq: true, name: "api_unique_request_index")
  end
end
