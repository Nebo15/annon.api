defmodule Gateway.UnitCase do
  @moduledoc """
  Gateway HTTP Test Helper
  """
  use ExUnit.CaseTemplate
  use Plug.Test

  using do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test
      import Gateway.UnitCase
    end
  end

  def assert_halt(%Plug.Conn{halted: true} = plug), do: plug
  def assert_not_halt(%Plug.Conn{halted: false} = plug), do: plug

  def assert_conn_status(conn, code \\ 200) do
    assert code == conn.status
    conn
  end

  def send_get(path) do
    :get
    |> conn(path)
    |> prepare_conn
  end

  def send_public_get(path) do
    :get
    |> conn(path)
    |> prepare_conn(Gateway.PublicRouter)
  end

  def send_delete(path) do
    :delete
    |> conn(path)
    |> prepare_conn
  end

  def send_post(path, data) do
    :post
    |> conn(path, Poison.encode!(data))
    |> prepare_conn
  end

  def send_put(path, data) do
    :put
    |> conn(path, Poison.encode!(data))
    |> prepare_conn
  end

  defp prepare_conn(conn, router \\ Gateway.PrivateRouter) do
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

  setup tags do
    :ets.delete_all_objects(:config)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Configs.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Logger.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Configs.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, {:shared, self()})
    end

    :ok
  end
end
