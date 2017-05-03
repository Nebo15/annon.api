defmodule Annon.Requests.Repo.Migrations.RenameLogsTable do
  use Ecto.Migration

  def change do
    rename table(:logs), to: table(:requests)
  end
end
