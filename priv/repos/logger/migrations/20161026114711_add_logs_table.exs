defmodule Gateway.Logger.DB.Repo.Migrations.AddLogsTable do
  use Ecto.Migration

  def change do
    create table(:logs) do
      add :api, :map
      add :consumer, :map
      add :idempotency_key, :string
      add :ip_address, :string
      add :request, :map
      add :response, :map
      add :latencies, :map
      add :status_code, :integer

      timestamps()
    end
  end
end
