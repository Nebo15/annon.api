defmodule Gateway.ControllerUnitCase do
  @moduledoc """
  Gateway HTTP Test Helper
  """
  use ExUnit.CaseTemplate

  using(opts) do
    quote bind_quoted: [opts: opts] do
      use ExUnit.Case, async: true
      use Plug.Test
      import Gateway.ControllerUnitCase

      unless opts[:controller] do
        throw "You need to specify controller when using Gateway.ControllerUnitCase in your tests"
      end

      @controller opts[:controller]

      def assert_conn_status(conn, code \\ 200) do
        assert code == conn.status
        conn
      end

      def send_get(path) do
        :get
        |> conn(path)
        |> prepare_conn
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

      defp prepare_conn(conn) do
        conn
        |> put_req_header("content-type", "application/json")
        |> @controller.call([])
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
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Configs.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Logger.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Configs.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, {:shared, self()})
    end

    :ets.delete_all_objects(:config)

    :ok
  end
end
