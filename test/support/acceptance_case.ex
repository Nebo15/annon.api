defmodule Annon.AcceptanceCase do
  @moduledoc """
  This module defines the test case to be used by
  acceptance tests. It can allow run tests in async when each SQL.Sandbox connection will be
  binded to a specific test.
  """

  use ExUnit.CaseTemplate
  import Joken

  using(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use HTTPoison.Base
      import Annon.AcceptanceCase

      # Load configuration from environment that allows to test Docker containers that run on another port
      @config Confex.get_env(:annon_api, :acceptance)

      def process_request_body(body) do
        body
        |> Poison.encode!
      end

      def process_response_body(""), do: nil
      def process_response_body(body) do
        body
        |> Poison.decode!
      end

      def process_request_headers(headers) when is_list(headers) do
        headers ++ [{"content-type", "application/json"}, magic_header()]
      end

      def get_public_url do
        port = get_endpoint_port(:public)
        host = get_endpoint_host(:public)

        "http://#{host}:#{port}/"
      end

      def get_private_url do
        port = get_endpoint_port(:private)
        host = get_endpoint_host(:private)

        "http://#{host}:#{port}/"
      end

      def get_management_url do
        port = get_endpoint_port(:management)
        host = get_endpoint_host(:management)

        "http://#{host}:#{port}/"
      end

      def put_public_url("/" <> url), do: get_public_url() <> url
      def put_public_url(url), do: get_public_url() <> url

      def put_private_url("/" <> url), do: get_private_url() <> url
      def put_private_url(url), do: get_private_url() <> url

      def put_management_url("/" <> url), do: get_management_url() <> url
      def put_management_url(url), do: get_management_url() <> url

      def create_api do
        :api
        |> build_factory_params()
        |> create_api()
      end

      def create_api(data) do
        api = "apis/#{data.id}"
        |> put_management_url()
        |> put!(%{"api" => data})
        |> assert_status(201)

        api
      end

      def update_api(api_id, data) do
        api = "apis/#{api_id}"
        |> put_management_url()
        |> put!(%{"api" => data})
        |> assert_status(200)

        api
      end

      def update_plugin(api_id, plugin_name, params) do
        plugin = "apis/#{api_id}/plugins/#{plugin_name}"
        |> put_management_url()
        |> put!(%{"plugin" => params})
        |> assert_status(200)

        plugin
      end

      def get_mock_response(%{"data" => data}), do: data
      def get_mock_response(%{"error" => error}), do: error

      def get_endpoint_port(endpoint_type), do: @config[endpoint_type][:port]
      def get_endpoint_host(endpoint_type), do: @config[endpoint_type][:host]

      def create_proxy_to_mock(api_id, settings \\ %{}) do
        settings = %{
          host: get_endpoint_host(:mock),
          port: get_endpoint_port(:mock)
        }
        |> Map.merge(settings)

        params = :proxy_plugin
        |> build_factory_params(%{settings: settings})

        proxy = "apis/#{api_id}/plugins/proxy"
        |> put_management_url()
        |> put!(%{"plugin" => params})
        |> assert_status(201)

        proxy
      end

      def magic_header do
        repos = [
          Annon.Configuration.Repo,
          Annon.Requests.Repo
        ]

        metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(repos, self())

        encoded_metadata =
          {:v1, metadata}
          |> :erlang.term_to_binary
          |> Base.url_encode64

        {"user-agent", "BeamMetadata (#{encoded_metadata})"}
      end

      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Annon.Configuration.Repo)
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Annon.Requests.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(Annon.Configuration.Repo, {:shared, self()})
          Ecto.Adapters.SQL.Sandbox.mode(Annon.Requests.Repo, {:shared, self()})
        end

        :ok
      end
    end
  end

  def build_invalid_plugin(plugin_name) when is_binary(plugin_name) do
    %{
      name: plugin_name,
      is_enabled: false,
      settings: %{"invalid" => "data"}
    }
  end

  def assert_status({:error, error}, _status) do
    assert false
    error
  end
  def assert_status({:ok, %HTTPoison.Response{} = response}, status), do: assert_status(response, status)
  def assert_status(%HTTPoison.Response{} = response, status) do
    if(response.status_code == status) do
      response
    else
      flunk "Expected response status #{inspect status}, got #{inspect response.status_code}. " <>
            "Response: #{inspect response}"
    end
  end

  def get_body(%HTTPoison.Response{body: body}), do: body

  def build_jwt_token(payload, signature) do
    payload
    |> token
    |> sign(hs256(signature))
    |> get_compact
  end

  def build_jwt_signature(signature) do
    Base.encode64(signature)
  end

  def build_factory_params(factory, overrides \\ []) do
    factory
    |> Annon.Factories.Configuration.build(overrides) # TODO: This can be replaced by params_for
    |> schema_to_map()
  end

  defp schema_to_map(schema) do
    schema
    |> Map.drop([:__struct__, :__meta__])
    |> Enum.reduce(%{}, fn
      {key, %Ecto.Association.NotLoaded{}}, acc ->
        acc
        |> Map.put(key, %{})
      {key, %{__struct__: _} = map}, acc ->
        acc
        |> Map.put(key, schema_to_map(map))
      {key, val}, acc ->
        acc
        |> Map.put(key, val)
    end)
  end
end
