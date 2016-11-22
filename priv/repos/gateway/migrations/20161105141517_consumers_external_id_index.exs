defmodule Gateway.DB.Configs.Repo.Migrations.ConsumersExternalIdIndex do
  use Ecto.Migration

  def change do
    create unique_index(:apis, [:name])
    create unique_index(:consumers, [:external_id])
  end
end
