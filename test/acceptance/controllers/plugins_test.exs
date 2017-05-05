defmodule Annon.Acceptance.Controllers.PluginsTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: true

  setup do
    api = create_api() |> get_body()
    api_id = get_in(api, ["data", "id"])

    %{api: api, api_id: api_id}
  end

  describe "JWT Plugin" do
    test "create", %{api_id: api_id} do
      jwt_plugin = :jwt_plugin
      |> build_factory_params()

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(jwt_plugin)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "jwt",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create with invalid settings", %{api_id: api_id} do
      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{})
      |> assert_status(422)

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(build_invalid_plugin("jwt"))
      |> assert_status(422)

      %{
        "error" => %{
          "invalid" => [%{"entry" => "$.settings.signature", "rules" => [
            %{"rule" => "cast", "params" => ["string" | _]} # TODO: Get rid from tail in params
          ]}]
        }
      } = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{name: "jwt", is_enabled: false, settings: %{"signature" => 1000}})
      |> assert_status(422)
      |> get_body()
    end

    test "create duplicates", %{api_id: api_id} do
      jwt_plugin = :jwt_plugin
      |> build_factory_params()

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(jwt_plugin)
      |> assert_status(201)

      actual_result = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(jwt_plugin)
      |> assert_status(422)
      |> get_body()
      |> get_in(["error", "invalid"])

      expected_result = [%{
        "entry" => "$.name",
        "entry_type" => "json_data_property",
        "rules" => [%{
          "description" => "has already been taken",
          "params" => [],
          "rule" => nil # TODO: Fix EView/Ecto to set "unique" in this case
        }]
      }]

      assert expected_result == actual_result
    end
  end

  describe "Validator Plugin" do
    test "create", %{api_id: api_id} do
      validator = :validator_plugin
      |> build_factory_params(%{settings: %{
        rules: [%{methods: ["POST", "PUT", "PATCH"], path: ".*", schema: %{}}]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(validator)
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
      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{})
      |> assert_status(422)

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(build_invalid_plugin("validator"))
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
      } = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{
        name: "validator",
        is_enabled: false,
        settings: %{
          rules: [%{methods: ["UNKNOWN"], path: 123, schema: nil}]
        }
      })
      |> assert_status(422)
      |> get_body()
    end
  end

  describe "ACL Plugin" do
    test "create", %{api_id: api_id} do
      acl = :acl_plugin
      |> build_factory_params()

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "acl",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create with invalid settings", %{api_id: api_id} do
      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{})
      |> assert_status(422)

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(build_invalid_plugin("acl"))
      |> assert_status(422)

      %{
        "error" => %{
          "invalid" => [%{"entry" => "$.settings.rules.[0].scopes", "rules" => [%{"rule" => "cast"}]}]
        }
      } = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{name: "acl",
        is_enabled: false,
        settings: %{rules: [%{"methods" => ["GET"], "path" => ".*", "scopes" => 100}]}
      })
      |> assert_status(422)
      |> get_body()
    end
  end

  describe "IPRestriction Plugin" do
    test "create whitelist", %{api_id: api_id} do
      ip_restriction = :ip_restriction_plugin
      |> build_factory_params(%{settings: %{whitelist: ["127.0.0.1"]}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(ip_restriction)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "ip_restriction",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create blacklist", %{api_id: api_id} do
      ip_restriction = :ip_restriction_plugin
      |> build_factory_params(%{settings: %{blacklist: ["127.0.0.1"]}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(ip_restriction)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "ip_restriction",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create whitelist and blacklist", %{api_id: api_id} do
      ip_restriction = :ip_restriction_plugin
      |> build_factory_params(%{settings: %{whitelist: ["127.0.0.1"], blacklist: ["127.0.0.1"]}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(ip_restriction)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "ip_restriction",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create with invalid settings", %{api_id: api_id} do
      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{})
      |> assert_status(422)

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(build_invalid_plugin("ip_restriction"))
      |> assert_status(422)

      %{
        "error" => %{
          "invalid" => [%{"entry" => "$.settings.blacklist", "rules" => [%{"rule" => "cast"}]}]
          # TODO: Test "params"
          # "invalid" => [%{"entry" => "$.settings.ip_whitelis", "rules" => [%{"rule" => "format"}]}]
          # TODO: different fields should not be merged together in one `entry`
        }
      } = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{
        name: "ip_restriction",
        is_enabled: false,
        settings: %{"blacklist" => 100} # , "whitelist" => ["127.0.0.256"]
      })
      |> assert_status(422)
      |> get_body()
    end
  end

  describe "Proxy Plugin" do
    test "create", %{api_id: api_id} do
      proxy = :proxy_plugin
      |> build_factory_params(%{settings: %{host: "host.com"}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(proxy)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "proxy",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create with invalid settings", %{api_id: api_id} do
      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{})
      |> assert_status(422)

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(build_invalid_plugin("proxy"))
      |> assert_status(422)

      %{
        "error" => %{
          "invalid" => [
            %{"entry" => "$.settings.host", "rules" => [%{"rule" => "schemata"}]},
            %{"entry" => "$.settings.path", "rules" => [%{"rule" => "cast"}]},
          ]
        }
      } = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{name: "proxy", is_enabled: false, settings: %{host: "localhost", path: 100}})
      |> assert_status(422)
      |> get_body()
    end
  end

  describe "Idempotency Plugin" do
    test "create", %{api_id: api_id} do
      idempotency = :idempotency_plugin
      |> build_factory_params()

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(idempotency)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "idempotency",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end
  end

  defp build_invalid_plugin(plugin_name) when is_binary(plugin_name) do
    %{
      name: plugin_name,
      is_enabled: false,
      settings: %{"invalid" => "data"}
    }
  end
end
