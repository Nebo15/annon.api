defmodule Annon.DB.Configs.Repo.Migrations.RenameAPIRequestMethods do
  use Ecto.Migration

  def change do
    columns = [
      "(request->>'host')",
      "(request->>'port')",
      "(request->>'path')",
      "(request->>'scheme')",
      "(request->>'methods')"
    ]
    drop index(:apis, columns, name: "api_unique_request_index")
    create unique_index(:apis, columns, uniq: true, name: "api_unique_request_index")
  end
end
