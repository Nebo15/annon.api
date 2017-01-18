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

  get "scopes" do
    response_body = %{
      "meta" => %{
        "code" => 200,
        "description" => "Success"
      },
      "data" => %{
        "scopes" => ["api:access"]
      }
    }

    send_resp(conn, 200, Poison.encode!(response_body))
  end

  get "empty_scopes" do
    response_body = %{
      "meta" => %{
        "code" => 200,
        "description" => "Success"
      },
      "data" => %{
        "scopes" => []
      }
    }

    send_resp(conn, 200, Poison.encode!(response_body))
  end
end
