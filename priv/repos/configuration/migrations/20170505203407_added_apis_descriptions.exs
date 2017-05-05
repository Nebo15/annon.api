defmodule Annon.Configuration.Repo.Migrations.AddedApisDescriptions do
  use Ecto.Migration

  def change do
    alter table(:apis) do
      add :description, :string, size: 512
      add :docs_url, :string, size: 512
      add :health, :string
      add :disclose_status, :boolean
    end
  end
end
