defmodule Annon.UnitCase do
  @moduledoc """
  Annon HTTP Test Helper
  """
  use ExUnit.CaseTemplate
  use Plug.Test

  using do
    quote do
      use Plug.Test
      import Annon.UnitCase

      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Annon.DB.Configs.Repo)
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Annon.DB.Logger.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(Annon.DB.Configs.Repo, {:shared, self()})
          Ecto.Adapters.SQL.Sandbox.mode(Annon.DB.Logger.Repo, {:shared, self()})
        end

        :ok
      end
    end
  end

  def assert_halt(%Plug.Conn{halted: true} = conn), do: conn
  def assert_halt(%Plug.Conn{halted: false}), do: flunk "connection is not halted"
  def assert_not_halt(%Plug.Conn{halted: false} = conn), do: conn
  def assert_not_halt(%Plug.Conn{halted: true}), do: flunk "connection is halted"

  def assert_conn_status(conn, code \\ 200) do
    assert code == conn.status
    conn
  end

  def call_get(path) do
    :get
    |> conn(path)
    |> call_router()
  end

  def call_public_router(path) do
    :get
    |> conn(path)
    |> call_router(Annon.PublicRouter)
  end

  def call_delete(path) do
    :delete
    |> conn(path)
    |> call_router()
  end

  def call_post(path, data) do
    :post
    |> conn(path, Poison.encode!(data))
    |> call_router()
  end

  def call_put(path, data) do
    :put
    |> conn(path, Poison.encode!(data))
    |> call_router()
  end

  defp call_router(conn, router \\ Annon.ManagementRouter) do
    conn
    |> put_req_header("content-type", "application/json")
    |> router.call([])
  end

  def assert_response_body(conn, expected_list) when is_list(expected_list) do
    conn.resp_body
    |> assert_body(expected_list, conn)

    conn
  end

  def assert_response_body(conn, expected_struct, dropped_keys \\ ["type"]) do
    dropped_keys
    |> List.foldr(conn.resp_body, &delete_data_field/2)
    |> assert_body(expected_struct, conn)

    conn
  end

  defp assert_body(resp_body, expected_struct, conn) do
    expected_body = expected_struct
    |> EView.wrap_body(conn)
    |> Poison.encode!

    assert expected_body == resp_body
  end

  defp delete_data_field(field, binary_json) when is_binary(binary_json) do
    binary_json = binary_json
    |> Poison.decode!()

    resp_data = binary_json
    |> Map.get("data")
    |> Map.delete(field)

    binary_json
    |> Map.put("data", resp_data)
    |> Poison.encode!()
  end

  def build_jwt_signature(signature) do
    Base.encode64(signature)
  end
end
