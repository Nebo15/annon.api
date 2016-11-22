defmodule Gateway.MockServer do
  @moduledoc false
  use Plug.Router
  require Logger
  alias Gateway.Helpers.Response

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

  match _ do
    conn
    |> debug_conn
    |> Response.send(conn, 200)
  end
end
