defmodule Gateway.UnitCase do
  @moduledoc """
  Gateway HTTP Test Helper
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test
      alias Gateway.DB.Models.Plugin
      alias Gateway.DB.Models.API, as: APIModel
      alias Gateway.DB.Models.Log
      import Gateway.UnitCase
      import Gateway.Fixtures
    end
  end

  def get(url, endpoint_type, headers \\ []), do: request(:get, endpoint_type, url, "", headers)
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

  def assert_halt(%Plug.Conn{halted: true} = plug), do: plug
  def assert_not_halt(%Plug.Conn{halted: false} = plug), do: plug

  setup tags do
    opts =
      case tags[:cluster] do
        true -> [sandbox: false]
        _ -> []
      end

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo, opts)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Logger.Repo, opts)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, {:shared, self()})
    end

    :ok
  end
end
