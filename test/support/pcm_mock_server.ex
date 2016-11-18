defmodule Gateway.PCMMockServer do
  @moduledoc """
  Mock server that simulates gettings scopes from PCM.
  """
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
                    pass:  ["application/json"],
                    json_decoder: Poison
  plug :dispatch

  @scopes_body %{"meta" => %{"code" => 200, "description" => "Success"}, "data" => %{"scopes" => ["api:access"]}}

  get "scopes", do: send_resp(conn, 200, Poison.encode!(@scopes_body))
end
