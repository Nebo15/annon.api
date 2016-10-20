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

      @config Confex.get_map(:gateway, :acceptance)

      def get(url, endpoint_type, headers \\ []), do: request(:get, endpoint_type, url, "", headers)
      def post(url, body, endpoint_type, headers \\ []), do: request(:post, endpoint_type, url, body, headers)

      def request(request_type, endpoint_type, url, body, custom_headers) do
        port = get_port(endpoint_type)
        host = get_host(endpoint_type)

        headers = [{"Content-Type", "application/json"} | custom_headers]

        HTTPoison.request(request_type, "http://#{host}:#{port}/#{url}", body, headers)
      end

      def get_port(endpoint_type), do: @config[endpoint_type][:port]
      def get_host(endpoint_type), do: @config[endpoint_type][:host]

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
          ["apis", "plugins", "consumers", "consumer_plugin_settings"]
          |> Enum.map(fn table -> truncate_table Gateway.DB.Repo, table end)
        end
      end

      defp truncate_table(repo, table) do
        Ecto.Adapters.SQL.query(repo, "TRUNCATE #{table} RESTART IDENTITY")
      end
    end
  end

end
