defmodule Annon.Plugins.UARestrictionTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.Plugins.UARestriction

  @user_agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"

  describe "settings_validation_schema/3" do
    test "accepts valid config" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "blacklist" => [@user_agent],
        "whitelist" => [@user_agent]
      }}}

      assert %Ecto.Changeset{valid?: true} = UARestriction.validate_settings(changeset)

      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "whitelist" => [@user_agent]
      }}}

      assert %Ecto.Changeset{valid?: true} = UARestriction.validate_settings(changeset)

      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "blacklist" => [@user_agent]
      }}}

      assert %Ecto.Changeset{valid?: true} = UARestriction.validate_settings(changeset)
    end
  end

  describe "execute/3" do
    test "skips request when no user agent is present", %{conn: conn} do
      settings = %{
        "blacklist" => ["Mozilla"],
        "whitelist" => ["Firefox"]
      }

      assert conn == UARestriction.execute(conn, nil, settings)
    end

    test "blacklists user agents", %{conn: conn} do
      settings = %{
        "blacklist" => ["Mozilla"],
        "whitelist" => ["Firefox"]
      }

      assert %{
        "error" => %{
          "message" => "You has been blocked from accessing this resource",
          "type" => "forbidden"
        }
      } = conn
      |> Conn.put_req_header("user-agent", @user_agent)
      |> UARestriction.execute(nil, settings)
      |> json_response(403)
    end

    test "whitelists user agents", %{conn: conn} do
      settings = %{
        "blacklist" => ["Mozilla"],
        "whitelist" => ["Chrome"]
      }

      conn = Conn.put_req_header(conn, "user-agent", @user_agent)
      assert conn == UARestriction.execute(conn, nil, settings)

      settings = %{
        "blacklist" => ["Moz.*"],
        "whitelist" => ["Chr.*"],
      }

      conn = Conn.put_req_header(conn, "user-agent", @user_agent)
      assert conn == UARestriction.execute(conn, nil, settings)
    end
  end
end
