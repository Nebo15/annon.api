defmodule Annon.PrivateRouter do
  @moduledoc """
  Router for a private APIs inside you clusters.
  """
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/", to: Annon.PublicAPI.Router
end
