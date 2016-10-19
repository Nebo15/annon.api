defmodule Gateway.AcceptanceCase do
  @moduledoc """
  This module defines the test case to be used by
  acceptance tests. It can allow run tests in async when each SQL.Sandbox connection will be
  binded to a specific test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Joken
      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 2]
      import Gateway.Fixtures

      alias Gateway.DB.Repo
      alias Gateway.DB.Models.Plugin
      alias Gateway.DB.Models.API, as: APIModel

      use HTTPoison.Base

      [port: port, host: host] = Confex.get_map(:gateway, :acceptance)

      @http_uri "http://#{host}:#{port}/"
      @port port

      def process_url(url) do
        @http_uri <> url
      end

      def get_port, do: @port

      defp process_request_headers(headers \\ []) do
        headers ++ [{"Content-Type", "application/json"}]
      end

      def process_response_body(body) do
        try do
          Poison.decode!(body)
        rescue
          _ -> body |> IO.inspect
        end
      end
      def assert_status({:ok, %HTTPoison.Response{} = response}, status), do: assert_status(response, status)
      def assert_status(%HTTPoison.Response{} = response, status) do
        assert response.status_code == status
        response
      end
      def get_body(%HTTPoison.Response{} = response), do: response.body

      def jwt_token(payload, signature) do
        payload
        |> token
        |> sign(hs256(signature))
        |> get_compact
      end

      setup do
        on_exit fn ->
          ["apis", "consumers", "plugins"]
          |> Enum.map(fn table -> truncate_table Gateway.DB.Repo, table end)
        end
      end

      defp truncate_table(repo, table) do
        Ecto.Adapters.SQL.query(repo, "TRUNCATE #{table} RESTART IDENTITY")
      end
    end
  end

end
