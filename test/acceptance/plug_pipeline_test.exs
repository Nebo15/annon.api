defmodule Gateway.Acceptance.PlugPipelineTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  @consumer_id random_string(32)
  @idempotency_key random_string(32)

  @payload %{"id" => @consumer_id, "name" => "John Doe", "scopes" => ["api_read", "api_create", "api_delete"]}
  @token_secret "pipeline_secret"

  @schema %{"type" => "object",
            "properties" => %{
              "description" => %{ "type" => "string"},
            },
            "required" => ["description"]
          }

  test "successful pipeline" do
    %HTTPoison.Response{body: created_api} = create_api()

    pipeline_data = "GET"
    |> api_data("/test/pipeline/api")
    |> Map.put("description", "cool description")
    |> Poison.encode!()

    %HTTPoison.Response{body: body1} = "pipeline"
    |> post(pipeline_data, :public, get_valid_headers())
    |> assert_status(201)

    %HTTPoison.Response{body: body2} = "pipeline"
    |> post(pipeline_data, :public, get_valid_headers())
    |> assert_status(201)

    %HTTPoison.Response{body: body3} = "pipeline"
    |> post(pipeline_data, :public, get_valid_headers())
    |> assert_status(201)

    assert body1 == body2
    assert body2 == body3

    assert Poison.decode!(created_api)["name"] == Poison.decode!(body1)["name"]
    assert Poison.decode!(created_api)["name"] == Poison.decode!(body2)["name"]
    assert Poison.decode!(created_api)["name"] == Poison.decode!(body3)["name"]
  end

  test "pipeline fails on validator" do
    create_api()

    pipeline_data = "GET"
    |> api_data("/test/pipeline/api")
    |> Poison.encode!()

    "pipeline"
    |> post(pipeline_data, :public, get_valid_headers())
    |> assert_status(422)
    |> assert_resp_body_json()

    assert_apis_amount(1)
  end

  test "pipeline fails on ACL" do
    create_api()

    pipeline_data = "GET"
    |> api_data("/test/pipeline/api")
    |> Poison.encode!()

    "pipeline"
    |> post(pipeline_data, :public)
    |> assert_status(401)
    |> assert_resp_body_json()

    "pipeline"
    |> post(pipeline_data, :public, [{"authorization", "Bearer #{jwt_token(@payload, "invalid_secret")}"}])
    |> assert_status(401)
    |> assert_resp_body_json()

    "pipeline"
    |> post(pipeline_data, :public, [{"authorization", "Bearer #{jwt_token(%{"scopes" => ["none"]}, @token_secret)}"}])
    |> assert_status(403)
    |> assert_resp_body_json()

    assert_apis_amount(1)
  end

  test "pipeline fails on invalid idempotency params" do
    create_api()

    pipeline_data = "GET"
    |> api_data("/test/pipeline/api")
    |> Map.put("description", "cool description")
    |> Poison.encode!()

    "pipeline"
    |> post(pipeline_data, :public, get_valid_headers())
    |> assert_status(201)
    |> assert_resp_body_json()

    "pipeline"
    |> post(~s({"name":"smth","description": "go"}), :public, get_valid_headers())
    |> assert_status(409)
    |> assert_resp_body_json()

    assert_apis_amount(2)
  end

  test "non-existent APIs" do
    pipeline_data = "GET"
    |> api_data("/test/pipeline/api")
    |> Poison.encode!()

    "pipeline"
    |> post(pipeline_data, :public, get_valid_headers())
    |> assert_status(404)
    |> assert_resp_body_json()

    assert_apis_amount(0)
  end

  defp assert_apis_amount(amount) do
    %HTTPoison.Response{body: body} = "apis"
    |> get(:management)
    |> assert_status(200)
    |> assert_resp_body_json()

    assert amount == body
    |> Poison.decode!()
    |> Map.get("data")
    |> Enum.count()
  end

  def create_api do
    result =
      "POST"
      |> api_data("/pipeline")
      |> http_api_create()

    Gateway.AutoClustering.do_reload_config()

    result
  end

  def api_data(method, path) do
    get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: path, port: get_port(:public), scheme: "http", method: [method]})
    |> Map.put(:plugins, get_plugins())
  end

  def get_plugins do
    [
      %{name: "acl", is_enabled: true, settings: %{"scope" => "api_create"}},
      %{name: "jwt", is_enabled: true, settings: %{"signature" => @token_secret}},
      %{name: "validator", is_enabled: true, settings: %{"schema" => Poison.encode!(@schema)}},
      %{name: "idempotency", is_enabled: true, settings: %{"key" => 100}},
      %{name: "proxy", is_enabled: true, settings: %{
          host: get_host(:management),
          path: "/apis",
          port: get_port(:management),
          scheme: "http"
        }
      }
    ]
  end

  def get_valid_headers do
    [
      {"authorization", "Bearer #{jwt_token(@payload, @token_secret)}"},
      {"x-idempotency-key", @idempotency_key}
    ]
  end
end
