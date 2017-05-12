defmodule Annon.MockServer do
  @moduledoc false
  use Plug.Router
  require Logger
  alias Annon.Helpers.Response

  plug :match

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison
  plug :dispatch

  defp debug_conn(conn) do
    %{
      request: %{
        method: conn.method,
        uri: conn.request_path,
        query: Plug.Conn.Query.decode(conn.query_string),
        headers: modify_headers_list(conn.req_headers),
        body: conn.body_params
      },
      response: %{
        status_code: conn.status,
        headers: modify_headers_list(conn.resp_headers),
        body: conn.resp_body
      }
    }
  end

  defp modify_headers_list([]), do: []
  defp modify_headers_list([{key, value} | t]), do: [%{key => value}] ++ modify_headers_list(t)

  match "/latency/*_" do
    :timer.sleep(200)
    conn
    |> debug_conn
    |> Response.send(conn, 200)
  end

  get "auth/mithril/users/:user_id" do
    response_body = %{
      "data" => %{
        "user_id" => user_id,
        "details" => %{
          "scope" => "api:access"
        }
      }
    }

    send_resp(conn, 200, Poison.encode!(response_body))
  end

  get "auth/consumers/:consumer_id" do
    response_body = %{
      "data" => %{
        "consumer_id" => consumer_id,
        "consumer_scope" => "api:access"
      }
    }

    send_resp(conn, 200, Poison.encode!(response_body))
  end

  get "auth/mithril/tokens/:access_token" do
    response_body = %{
      "data" => %{
        "id" => access_token,
        "user_id" => "bob",
        "details" => %{
          "scope" => "api:access"
        }
      }
    }

    send_resp(conn, 200, Poison.encode!(response_body))
  end

  get "auth/tokens/:access_token" do
    response_body = %{
      "data" => %{
        "id" => access_token,
        "consumer_id" => "bob",
        "consumer_scope" => "api:access"
      }
    }

    send_resp(conn, 200, Poison.encode!(response_body))
  end

  match _ do
    conn
    |> debug_conn
    |> Response.send(conn, 200)
  end
end
