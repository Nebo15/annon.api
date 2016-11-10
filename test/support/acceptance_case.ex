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
      import Gateway.AcceptanceCase

      alias Gateway.DB.Configs.Repo
      alias Gateway.DB.Schemas.Plugin
      alias Gateway.DB.Schemas.API, as: APISchema

      @config Confex.get_map(:gateway, :acceptance)

      def get(url, endpoint_type, headers \\ []), do: request(:get, endpoint_type, url, "", headers)
      def put(url, body, endpoint_type, headers \\ []), do: request(:put, endpoint_type, url, body, headers)
      def post(url, body, endpoint_type, headers \\ []), do: request(:post, endpoint_type, url, body, headers)
      def delete(url, endpoint_type, headers \\ []), do: request(:delete, endpoint_type, url, "", headers)

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

      def http_api_create(data) do
        "apis"
        |> post(Poison.encode!(data), :private)
        |> assert_status(201)
        |> assert_resp_body_json()
      end

      def assert_resp_body_json(%HTTPoison.Response{body: body} = resp) do
        assert {:ok, _} = Poison.decode(body)
        resp
      end

      setup tags do
        opts =
          case tags[:cluster] do
            true -> [sandbox: false]
            _ -> []
          end

        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Configs.Repo, opts)
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Logger.Repo, opts)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Configs.Repo, {:shared, self()})
          Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, {:shared, self()})
        end

        ["apis", "plugins", "consumers", "consumer_plugin_settings"]
        |> Enum.map(fn table -> truncate_table Gateway.DB.Configs.Repo, table end)

        ["logs"]
        |> Enum.map(fn table -> truncate_table Gateway.DB.Logger.Repo, table end)

        :ets.delete_all_objects(:config)

        :ok
      end

      defp truncate_table(repo, table) do
        Ecto.Adapters.SQL.query(repo, "TRUNCATE #{table} RESTART IDENTITY")
      end
    end
  end

  def random_string(length) do
    data = :crypto.strong_rand_bytes(length)
    data |> Base.url_encode64 |> binary_part(0, length)
  end
end
