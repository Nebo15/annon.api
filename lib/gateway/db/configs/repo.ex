defmodule Gateway.DB.Configs.Repo do
  use Ecto.Repo, otp_app: :gateway
  use Ecto.Pagging.Repo
end
