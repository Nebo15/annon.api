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

  def assert_response_body(conn, expected_struct) do
    resp_body = conn.resp_body
    |> Poison.decode!()

    resp_data = resp_body
    |> Map.get("data")
    |> Map.delete("type")

    resp_body = resp_body
    |> Map.put("data", resp_data)
    |> Poison.encode!()

    expected_body = expected_struct
    |> EView.wrap_body(conn)
    |> Poison.encode!

    assert expected_body == resp_body
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
