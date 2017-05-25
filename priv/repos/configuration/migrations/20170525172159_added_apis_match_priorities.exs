defmodule Annon.Configuration.Repo.Migrations.AddedApisMatchPriorities do
  use Ecto.Migration

  def change do
    alter table(:apis) do
      add :matching_priority, :integer, default: 1, null: false
    end
  end
end
