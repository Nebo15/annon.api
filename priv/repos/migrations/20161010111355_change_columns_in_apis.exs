defmodule Gateway.DB.Repo.Migrations.ChangeColumnsInApis do
  use Ecto.Migration

  def change do
    alter table(:apis) do
      remove :scheme
      remove :host
      remove :port
      remove :path

      add :request, :map
    end
  end
end
