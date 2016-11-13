defmodule Gateway.Acceptance.Plugins.ValidatorTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  @schema %{"type" => "object",
            "properties" => %{"foo" => %{"type" => "number"}, "bar" => %{ "type" => "string"}},
            "required" => ["bar"]}

  setup do
    api_path = "/my_validated_api"
    api = :api
    |> build_factory_params(%{
      request: %{
        method: ["GET", "POST", "PUT", "DELETE"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: api_path
      }
    })
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    %{api_id: api_id, api_path: api_path}
  end

  test "validates versus schema", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [%{methods: ["GET", "POST", "PUT", "DELETE"], path: ".*", schema: @schema}]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(validator_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    assert %{
      "error" => %{"type" => "validation_failed"}
    } = api_path
    |> put_public_url()
    |> post!(%{data: "aaaa"})
    |> assert_status(422)
    |> get_body()

    api_path
    |> put_public_url()
    |> post!(%{bar: "foo"})
    |> assert_status(404)
  end

  test "works without matching rules", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [%{methods: ["DELETE"], path: ".*", schema: @schema}]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(validator_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    api_path
    |> put_public_url()
    |> post!(%{data: "aaaa"})
    |> assert_status(404)
    |> get_body()
  end

  test "first of many rules is applied", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["GET", "POST", "PUT", "DELETE"], path: ".*", schema: %{}}, # Allow request
        %{methods: ["GET", "POST", "PUT", "DELETE"], path: ".*", schema: @schema} # And deny it
      ]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(validator_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    api_path
    |> put_public_url()
    |> post!(%{data: "aaaa"})
    |> assert_status(404)
    |> get_body()
  end

  test "following rules can't cancel validation results", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["GET", "POST", "PUT", "DELETE"], path: ".*", schema: @schema},
        %{methods: ["GET", "POST", "PUT", "DELETE"], path: ".*", schema: %{}}
      ]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(validator_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    api_path
    |> put_public_url()
    |> post!(%{data: "aaaa"})
    |> assert_status(422)
    |> get_body()
  end

  describe "rules is filtered" do
    test "by method", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["PUT", "DELETE"], path: ".*", schema: @schema},
        %{methods: ["POST"], path: ".*", schema: %{}}
      ]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(validator_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    api_path
    |> put_public_url()
    |> post!(%{data: "aaaa"})
    |> assert_status(404)
    |> get_body()
    end

    test "by path", %{api_id: api_id, api_path: api_path} do
      validator_plugin = :validator_plugin
      |> build_factory_params(%{settings: %{
        rules: [
          %{methods: ["POST"], path: "^/foo$", schema: @schema}
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(validator_plugin)
      |> assert_status(201)

      Gateway.AutoClustering.do_reload_config()

      "#{api_path}/foo"
      |> put_public_url()
      |> post!(%{data: "aaaa"})
      |> assert_status(422)
      |> get_body()
    end
  end
end
