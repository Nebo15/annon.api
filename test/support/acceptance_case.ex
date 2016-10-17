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

      alias Gateway.DB.Repo

      use HTTPoison.Base

      # Configure acceptance testing on different host:port
      conf = Application.get_env(:gateway, :http)
      host = System.get_env("MIX_TEST_HOST") || conf[:http][:host] || "localhost"
      port = System.get_env("MIX_TEST_PORT") || conf[:http][:port] || 4000

      @http_uri "http://#{host}:#{port}/"

      def process_url(url) do
        @http_uri <> url
      end

      defp process_request_headers(_) do
        [{"Content-Type", "application/json"}]
      end

      def process_response_body(body), do: Poison.decode!(body, keys: :atoms!)
      def assert_status({:ok, %HTTPoison.Response{} = response}, status), do: assert_status(response, status)
      def assert_status(%HTTPoison.Response{} = response, status) do
        assert response.status_code == status
        response
      end

      def get_body(%HTTPoison.Response{} = response), do: response.body
    end
  end

end
