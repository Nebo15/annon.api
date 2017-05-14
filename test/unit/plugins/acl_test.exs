defmodule Annon.Plugins.ACLTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.Factories.Configuration, as: ConfigurationFactory
  alias Annon.PublicAPI.Consumer
  alias Annon.Plugins.ACL

  describe "settings_validation_schema/3" do
    test "accepts rules config" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "rules" => [
          %{
            "methods" => ["GET"],
            "path" => "/does_not_exist",
            "scopes" => ["some_resource:read"]
          }
        ]
      }}}

      assert %Ecto.Changeset{valid?: true} = ACL.validate_settings(changeset)
    end

    test "requires path" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "rules" => [
          %{
            "methods" => [],
            "path" => "",
            "scopes" => ["abc"]
          }
        ]
      }}}

      assert %Ecto.Changeset{valid?: false} = ACL.validate_settings(changeset)
    end

    test "requires at least one scope" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "rules" => [
          %{
            "methods" => ["GET"],
            "path" => "/does_not_exist",
            "scopes" => []
          }
        ]
      }}}

      assert %Ecto.Changeset{valid?: false} = ACL.validate_settings(changeset)
    end

    test "requires at least one method" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "rules" => [
          %{
            "methods" => [],
            "path" => "/does_not_exist",
            "scopes" => ["abc"]
          }
        ]
      }}}

      assert %Ecto.Changeset{valid?: false} = ACL.validate_settings(changeset)
    end

    test "requires at least one rule" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "rules" => []
      }}}

      assert %Ecto.Changeset{valid?: false} = ACL.validate_settings(changeset)
    end
  end

  describe "execute/3" do
    setup %{conn: conn} do
      api = ConfigurationFactory.build(:api)

      %{
        conn: conn,
        api: api
      }
    end

    test "returns forbidden when scope is not set", %{conn: conn, api: api} do
      acl_plugin = ConfigurationFactory.build(:acl_plugin)
      settings = acl_plugin.settings

      assert %{
        "error" => %{
          "message" => "You are not authorized or your token can not be resolved to scope",
          "type" => "forbidden"
        }
      } = conn
      |> ACL.execute(%{api: api}, settings)
      |> json_response(403)
    end

    test "returns forbidden when scope does not match for path", %{conn: conn, api: api} do
      acl_plugin = ConfigurationFactory.build(:acl_plugin)
      settings = acl_plugin.settings

      assert %{
        "error" => %{
          "message" => "Your scope does not allow to access this resource. Missing allowances: some_resource:read",
          "type" => "forbidden"
        }
      } = conn
      |> Conn.assign(:consumer, %Consumer{id: "bob", scope: "apis:list"})
      |> ACL.execute(%{api: api}, settings)
      |> json_response(403)
    end

    test "returns forbidden when no rule is set for path", %{conn: conn, api: api} do
      settings = %{
        "rules" => [
          %{
            "methods" => ["GET"],
            "path" => "/does_not_exist",
            "scopes" => ["some_resource:read"]
          }
        ]
      }

      assert %{
        "error" => %{
          "message" => "You are not authorized or your token can not be resolved to scope",
          "type" => "forbidden"
        }
      } = conn
      |> Conn.assign(:consumer, %Consumer{id: "bob", scope: "apis:list"})
      |> ACL.execute(%{api: api}, settings)
      |> json_response(403)
    end

    test "returns forbidden when no some allowances are missing", %{conn: conn, api: api} do
      settings = %{
        "rules" => [
          %{
            "methods" => ["GET"],
            "path" => ".*",
            "scopes" => ["some_resource:read", "some_resource:access"]
          }
        ]
      }

      assert %{
        "error" => %{
          "message" => "Your scope does not allow to access this resource. Missing allowances: some_resource:access",
          "type" => "forbidden"
        }
      } = conn
      |> Conn.assign(:consumer, %Consumer{id: "bob", scope: "some_resource:read"})
      |> ACL.execute(%{api: api}, settings)
      |> json_response(403)
    end

    test "returns forbidden when consumer has empty scope", %{conn: conn, api: api} do
      settings = %{
        "rules" => [
          %{
            "methods" => ["GET"],
            "path" => ".*",
            "scopes" => ["some_resource:read"]
          }
        ]
      }

      assert %{
        "error" => %{
          "message" => "Your scope does not allow to access this resource. Missing allowances: some_resource:read",
          "type" => "forbidden"
        }
      } = conn
      |> Conn.assign(:consumer, %Consumer{id: "bob", scope: ""})
      |> ACL.execute(%{api: api}, settings)
      |> json_response(403)
    end

    test "uses first matched rule", %{conn: conn, api: api} do
      settings = %{
        "rules" => [
          %{
            "methods" => ["GET"],
            "path" => ".*",
            "scopes" => ["some_resource:read", "some_resource:access"]
          },
          %{
            "methods" => ["GET"],
            "path" => ".*",
            "scopes" => ["other_scope:read"]
          }
        ]
      }

      assert %{
        "error" => %{
          "message" => "Your scope does not allow to access this resource. " <>
                       "Missing allowances: some_resource:read, some_resource:access",
          "type" => "forbidden"
        }
      } = conn
      |> Conn.assign(:consumer, %Consumer{id: "bob", scope: "other_scope:read"})
      |> ACL.execute(%{api: api}, settings)
      |> json_response(403)
    end

    test "filters rules by method", %{conn: conn, api: api} do
      settings = %{
        "rules" => [
          %{
            "methods" => ["POST"],
            "path" => ".*",
            "scopes" => ["some_resource:read", "some_resource:access"]
          },
          %{
            "methods" => ["GET"],
            "path" => ".*",
            "scopes" => ["other_scope:read"]
          }
        ]
      }

      conn = Conn.assign(conn, :consumer, %Consumer{id: "bob", scope: "other_scope:read"})
      assert conn == ACL.execute(conn, %{api: api}, settings)
    end

    test "filters rules by path pattern", %{api: api} do
      settings = %{
        "rules" => [
          %{
            "methods" => ["GET"],
            "path" => "/foo",
            "scopes" => ["some_resource:read", "some_resource:access"]
          },
          %{
            "methods" => ["GET"],
            "path" => "/bar",
            "scopes" => ["other_scope:read"]
          }
        ]
      }

      conn =
        :get
        |> build_conn("/bar", nil)
        |> Conn.assign(:consumer, %Consumer{id: "bob", scope: "other_scope:read"})

      assert conn == ACL.execute(conn, %{api: api}, settings)
    end
  end
end
