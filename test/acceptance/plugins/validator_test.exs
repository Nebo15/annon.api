defmodule Annon.Acceptance.Plugins.ValidatorTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: true

  @schema %{"type" => "object",
            "properties" => %{"foo" => %{"type" => "number"}, "bar" => %{ "type" => "string"}},
            "required" => ["bar"]}

  setup do
    api_path = "/my_validated_api-" <> Ecto.UUID.generate() <> "/"
    api = :api
    |> build_factory_params(%{
      request: %{
        methods: ["GET", "POST", "PUT", "DELETE"],
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

  describe "Validator Plugin" do
    test "create", %{api_id: api_id} do
      validator = :validator_plugin
      |> build_factory_params(%{settings: %{
        rules: [%{methods: ["POST", "PUT", "PATCH"], path: "/.*", schema: %{}}]
      }})

      "apis/#{api_id}/plugins/validator"
      |> put_management_url()
      |> put!(%{"plugin" => validator})
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "validator",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create with invalid settings", %{api_id: api_id} do
      "apis/#{api_id}/plugins/validator"
      |> put_management_url()
      |> put!(%{"plugin" => %{}})
      |> assert_status(422)

      "apis/#{api_id}/plugins/validator"
      |> put_management_url()
      |> put!(%{"plugin" => build_invalid_plugin("validator")})
      |> assert_status(422)

      %{
        "error" => %{
          "invalid" => [
            %{"entry" => "$.settings.rules.[0].methods.[0]", "rules" => [
              %{"params" => ["POST", "PUT", "PATCH"], "rule" => "inclusion"}
            ]},
            %{"entry" => "$.settings.rules.[0].path", "rules" => [
              %{"params" => ["string", _], "rule" => "cast"} # TODO: Remove tail from "params"
            ]},
            %{"entry" => "$.settings.rules.[0].schema", "rules" => [
              %{"params" => ["object", _], "rule" => "cast"} # TODO: Remove tail from "params"
            ]}
          ]

        }
      } = "apis/#{api_id}/plugins/validator"
      |> put_management_url()
      |> put!(%{"plugin" => %{
        name: "validator",
        is_enabled: false,
        settings: %{
          rules: [%{methods: ["UNKNOWN"], path: 123, schema: nil}]
        }
      }})
      |> assert_status(422)
      |> get_body()
    end
  end

  test "validates versus schema", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [%{methods: ["POST", "PUT"], path: "/.*", schema: @schema}]
    }})

    "apis/#{api_id}/plugins/validator"
    |> put_management_url()
    |> put!(%{"plugin" => validator_plugin})
    |> assert_status(201)

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
      rules: [%{methods: ["PATCH"], path: "/.*", schema: @schema}]
    }})

    "apis/#{api_id}/plugins/validator"
    |> put_management_url()
    |> put!(%{"plugin" => validator_plugin})
    |> assert_status(201)

    api_path
    |> put_public_url()
    |> post!(%{"plugin" => %{data: "aaaa"}})
    |> assert_status(404)
    |> get_body()
  end

  test "first of many rules is applied", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["POST", "PUT", "PATCH"], path: "/.*", schema: %{}}, # Allow request
        %{methods: ["POST", "PUT", "PATCH"], path: "/.*", schema: @schema} # And deny it
      ]
    }})

    "apis/#{api_id}/plugins/validator"
    |> put_management_url()
    |> put!(%{"plugin" => validator_plugin})
    |> assert_status(201)

    api_path
    |> put_public_url()
    |> post!(%{"plugin" => %{data: "aaaa"}})
    |> assert_status(404)
    |> get_body()
  end

  test "following rules can't cancel validation results", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["POST", "PUT"], path: "/.*", schema: @schema},
        %{methods: ["POST", "PUT"], path: "/.*", schema: %{}}
      ]
    }})

    "apis/#{api_id}/plugins/validator"
    |> put_management_url()
    |> put!(%{"plugin" => validator_plugin})
    |> assert_status(201)

    api_path
    |> put_public_url()
    |> post!(%{"plugin" => %{data: "aaaa"}})
    |> assert_status(422)
    |> get_body()
  end

  describe "rules is filtered" do
    test "by method", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["PUT", "PATCH"], path: "/.*", schema: @schema},
        %{methods: ["POST"], path: "/.*", schema: %{}}
      ]
    }})

    "apis/#{api_id}/plugins/validator"
    |> put_management_url()
    |> put!(%{"plugin" => validator_plugin})
    |> assert_status(201)

    api_path
    |> put_public_url()
    |> post!(%{"plugin" => %{data: "aaaa"}})
    |> assert_status(404)
    |> get_body()
    end

    test "by path", %{api_id: api_id, api_path: api_path} do
      validator_plugin = :validator_plugin
      |> build_factory_params(%{settings: %{
        rules: [
          %{methods: ["POST"], path: "/foo$", schema: @schema}
        ]
      }})

      "apis/#{api_id}/plugins/validator"
      |> put_management_url()
      |> put!(%{"plugin" => validator_plugin})
      |> assert_status(201)

      "#{api_path}foo"
      |> put_public_url()
      |> post!(%{"plugin" => %{data: "aaaa"}})
      |> assert_status(422)
      |> get_body()
    end
  end
end
