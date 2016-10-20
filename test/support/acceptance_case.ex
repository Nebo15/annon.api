defmodule Gateway.AcceptanceCase do
  @moduledoc """
  This module defines the test case to be used by
  acceptance tests. It can allow run tests in async when each SQL.Sandbox connection will be
  binded to a specific test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 2]
      import Gateway.Fixtures

      alias Gateway.DB.Repo
      alias Gateway.DB.Models.Plugin
      alias Gateway.DB.Models.API, as: APIModel

      @config Confex.get_map(:gateway, :acceptance)

      def get(url, endpoint_type), do: request(:get, endpoint_type, url, "")
      def post(url, body, endpoint_type), do: request(:post, endpoint_type, url, body)

      def request(request_type, endpoint_type, url, body) do
        port = Keyword.get(@config, endpoint_type)[:port]
        host = Keyword.get(@config, endpoint_type)[:host]

        headers = [
          {"Content-Type", "application/json"}
        ]

        HTTPoison.request(request_type, "http://#{host}:#{port}/#{url}", body, headers)
      end

      def get_port(type) do
        @config[type][:port]
      end

      def assert_status({:ok, %HTTPoison.Response{} = response}, status), do: assert_status(response, status)
      def assert_status(%HTTPoison.Response{} = response, status) do
        assert response.status_code == status
        response
      end
      def get_body(%HTTPoison.Response{} = response), do: response.body

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
