defmodule Keepex.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  forward "/apis", to: Keepex.Crud.Collection
end
