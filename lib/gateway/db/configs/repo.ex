defmodule Gateway.DB.Configs.Repo do
  @moduledoc """
  Main repository for DB that stores configuration.

  This database doesn't need to have high performance, since all data is
  [fetched once and cached in Annon](http://docs.annon.apiary.io/#introduction/general-features/caching-and-perfomance).
  """

  use Ecto.Repo, otp_app: :gateway
end
