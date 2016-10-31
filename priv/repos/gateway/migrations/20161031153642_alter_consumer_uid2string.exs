defmodule Gateway.DB.Repo.Migrations.AlterConsumerUid2string do
  use Ecto.Migration

  def change do
    alter table(:consumers) do
      remove :external_id
      add :external_id, :string
    end    
  end
end
