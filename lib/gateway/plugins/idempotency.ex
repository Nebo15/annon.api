defmodule Gateway.Plugins.Idempotency do
  @moduledoc """
    Plugin for Idempotency
  """
  import Plug.Conn

  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  def init([]), do: false

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> get_enabled()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, _conn), do: true
  defp execute(%Plugin{}, %Plug.Conn{} = conn) do
    conn
    |> get_req_header("x-idempotency-key")
    |> load_request
    |> normalize_resp(conn)
  end

  defp load_request([key]) when is_binary(key) do
    # ToDo: load request from cassandra
    {:ok, [%{
      response: Poison.encode!(%{
        headers: %{"x-request-id" => "9a2bd452-99e6-11e6-9fd4-685b35cd61c2", "content-type" => "application/json"},
        body: %{meta: %{code: 200}}
      }),
      status_code: 200
    }]}

  end
  defp load_request(_), do: nil

  defp normalize_resp({:ok, [%{response: response, status_code: code}]}, conn) do
    response = Poison.decode!(response)
    conn
    |> merge_resp_headers(response["headers"])
    |> send_resp(code, Poison.encode!(response["body"]))
    |> halt
  end
  defp normalize_resp(_, conn), do: conn

  defp send_halt(conn, code, message) do
    conn
    |> send_resp(code, create_json_response(code, message))
    |> halt
  end

  defp create_json_response(code, message) do
    Poison.encode!(%{
      meta: %{
        code: code,
        error: message
      }
    })
  end

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end
  defp filter_plugin(%Plugin{name: :Idempotency, is_enabled: true}), do: true
  defp filter_plugin(_), do: false
end
