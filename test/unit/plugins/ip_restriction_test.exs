defmodule Annon.Plugins.IPRestrictionTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.Plugins.IPRestriction

  describe "settings_validation_schema/3" do
    test "accepts valid config" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "blacklist" => ["127.0.0.*"],
        "whitelist" => ["128.30.50.245"]
      }}}

      assert %Ecto.Changeset{valid?: true} = IPRestriction.validate_settings(changeset)

      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "blacklist" => ["127.0.0.*"]
      }}}

      assert %Ecto.Changeset{valid?: true} = IPRestriction.validate_settings(changeset)

      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "whitelist" => ["127.0.0.*"]
      }}}

      assert %Ecto.Changeset{valid?: true} = IPRestriction.validate_settings(changeset)
    end

    test "validate IP patterns" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "blacklist" => ["a127.0.0.*"],
        "whitelist" => ["128.30.50.245"]
      }}}

      assert %Ecto.Changeset{valid?: false} = IPRestriction.validate_settings(changeset)

      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "blacklist" => ["127.0.0.0/100"],
        "whitelist" => ["128.30.50.245/ab"]
      }}}

      assert %Ecto.Changeset{valid?: false} = IPRestriction.validate_settings(changeset)
    end
  end

  describe "execute/3" do
    test "blacklists IPv4 addresses", %{conn: conn} do
      settings = %{
        "blacklist" => ["127.0.0.*"],
        "whitelist" => ["128.30.50.245"]
      }

      assert %{
        "error" => %{
          "message" => "You has been blocked from accessing this resource",
          "type" => "forbidden"
        }
      } = conn
      |> Map.put(:remote_ip, {127, 0, 0, 1})
      |> IPRestriction.execute(nil, settings)
      |> json_response(403)
    end

    test "whitelists IPv4 addresses", %{conn: conn} do
      settings = %{
        "blacklist" => ["128.30.50.245"],
        "whitelist" => ["127.0.0.*"],
      }

      conn = Map.put(conn, :remote_ip, {127, 0, 0, 1})
      assert conn == IPRestriction.execute(conn, nil, settings)

      settings = %{
        "blacklist" => ["127.0.0.1"],
        "whitelist" => ["127.0.0.*"],
      }

      conn = Map.put(conn, :remote_ip, {127, 0, 0, 1})
      assert conn == IPRestriction.execute(conn, nil, settings)

      settings = %{
        "blacklist" => ["127.0.0.1"],
        "whitelist" => ["127.0.0.0/24"]
      }

      conn = Map.put(conn, :remote_ip, {127, 0, 0, 253})
      assert conn == IPRestriction.execute(conn, nil, settings)
    end
  end
end
