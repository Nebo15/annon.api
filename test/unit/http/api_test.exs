defmodule Gateway.HTTP.APITest do
  use ExUnit.Case, async: true

  use Plug.Test

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo)

    # Ecto.Adapters.Postgres.storage_down(Gateway.DB.Repo.config)
    # Ecto.Adapters.Postgres.storage_up(Gateway.DB.Repo.config)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Repo, {:shared, self()})
    end

    :ok
  end

  test "GET /apis" do
    data =
      [
        Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }}),
        Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }})
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn =
      conn(:get, "/")
      |> Gateway.HTTP.API.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: data
    }

    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(expected_resp)
  end
end
