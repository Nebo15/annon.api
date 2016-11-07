defmodule Gateway.DB.Configs.Repo.Migrations.AddStripRequestPathFlagToApis do
  use Ecto.Migration

  def change do
    alter table(:apis) do
      add :strip_request_path, :boolean, default: false
    end
  end
end
