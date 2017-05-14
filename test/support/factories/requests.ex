defmodule Annon.Factories.Requests do
  @moduledoc """
  This module lists Requests-related factories, a mean suitable
  for tests that involve preparation of DB data.
  """
  use ExMachina.Ecto, repo: Annon.Requests.Repo

  # Requests

  def request_factory do
    %Annon.Requests.Request{
      id: Ecto.UUID.generate(),
      idempotency_key: Ecto.UUID.generate(),
      ip_address: "129.168.1.10",
      status_code: 200,
      api: build(:api),
      request: build(:http_request),
      response: build(:http_response),
      latencies: build(:latencies),
    }
  end

  def api_factory do
    %Annon.Requests.Request.API{
      id: sequence(:request_id, &to_string/1),
      name: sequence(:api_name, &"An API ##{&1}"),
      request: build(:api_request)
    }
  end

  def api_request_factory do
    %Annon.Requests.Request.API.Request{
      scheme: "http",
      host: sequence(:host, &"www.example#{&1}.com"),
      port: 80,
      path: "/my_api/"
    }
  end

  def http_request_factory do
    %Annon.Requests.Request.HTTPRequest{
      method: "GET",
      uri: "/my_api/",
      query: %{"key" => "value"},
      headers: [%{"content-type" => "application/json"}],
      body: "{}"
    }
  end

  def http_response_factory do
    %Annon.Requests.Request.HTTPResponse{
      status_code: 200,
      headers: [%{"content-type" => "application/json"}],
      body: ""
    }
  end

  def latencies_factory do
    %Annon.Requests.Request.Latencies{
      gateway: 2,
      upstream: 100,
      client_request: 102
    }
  end
end
