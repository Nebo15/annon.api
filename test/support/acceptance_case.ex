defmodule Gateway.AcceptanceCase do
  @moduledoc """
  This module defines the test case to be used by
  acceptance tests. It can allow run tests in async when each SQL.Sandbox connection will be
  binded to a specific test.
  """

  use ExUnit.CaseTemplate
  import Joken

  using(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      import Gateway.AcceptanceCase

      # Load configuration from environment that allows to test Docker containers that run on another port

      def get_mock_response(%{"data" => data}), do: data
      def get_mock_response(%{"error" => error}), do: error

      def create_proxy_to_mock(api_id, settings \\ %{}) do
        settings = %{
          host: get_endpoint_host(:mock),
          port: get_endpoint_port(:mock)
        }
        |> Map.merge(settings)

        params = :proxy_plugin
        |> build_factory_params(%{settings: settings})

        proxy = "apis/#{api_id}/plugins"
        |> put_management_url()
        |> post!(params)
        |> assert_status(201)

        proxy
      end

      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Configs.Repo)
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Logger.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Configs.Repo, {:shared, self()})
          Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, {:shared, self()})
        end

        :ok
      end
    end
  end

  @config Confex.get_map(:gateway, :acceptance)

  def magic_header do
    repos = [
      Gateway.DB.Configs.Repo,
      Gateway.DB.Logger.Repo
    ]

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(repos, self())

    encoded_metadata =
      {:v1, metadata}
      |> :erlang.term_to_binary
      |> Base.url_encode64

    {"user-agent", "BeamMetadata (#{encoded_metadata})"}
  end

  def put!(url, body) do
    resp = HTTPoison.put!(url, Poison.encode!(body), [{"Content-Type", "application/json"}, magic_header()])
    Map.put(resp, :body, Poison.decode!(resp.body))
  end

  def post!(url, body) do
    resp = HTTPoison.post!(url, Poison.encode!(body), [{"Content-Type", "application/json"}, magic_header()])
    Map.put(resp, :body, Poison.decode!(resp.body))
  end

  def get!(url) do
    resp = HTTPoison.get!(url, [{"Content-Type", "application/json"}, magic_header()])
    Map.put(resp, :body, Poison.decode!(resp.body))
  end

  def get_endpoint_port(endpoint_type), do: @config[endpoint_type][:port]
  def get_endpoint_host(endpoint_type), do: @config[endpoint_type][:host]

  def get_public_url do
    port = get_endpoint_port(:public)
    host = get_endpoint_host(:public)

    "http://#{host}:#{port}/"
  end

  def get_management_url do
    port = get_endpoint_port(:management)
    host = get_endpoint_host(:management)

    "http://#{host}:#{port}/"
  end

  def put_public_url("/" <> url), do: get_public_url() <> url
  def put_public_url(url), do: get_public_url() <> url

  def put_management_url("/" <> url), do: get_management_url() <> url
  def put_management_url(url), do: get_management_url() <> url

  def create_api do
    :api
    |> build_factory_params()
    |> create_api()
  end

  def create_api(data) do
    api = "apis"
    |> put_management_url()
    |> post!(data)
    |> assert_status(201)

    api
  end

  def update_api(api_id, data) do
    api = "apis/#{api_id}"
    |> put_management_url()
    |> put!(data)
    |> assert_status(200)

    api
  end

  def update_plugin(api_id, plugin_name, params) do
    plugin = "apis/#{api_id}/plugins/proxy"
    |> put_management_url()
    |> put!(params)
    |> assert_status(200)

    plugin
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
    |> Gateway.Factory.build(overrides)
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
