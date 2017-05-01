defmodule Annon.Validators.SettingsTest do
  use Annon.UnitCase, async: true

  describe "ACL plugin validation" do
    test "Valid settings" do
      rules = [
        %{"methods" => ["GET", "POST", "PUT", "DELETE"], "path" => ".*", "scopes" => ["request_api"]},
        %{"methods" => ["GET"], "path" => "^/profiles/me$", "scopes" => ["read_profile"]},
        %{"methods" => ["POST", "PUT"], "path" => "^/profiles/me$", "scopes" => ["update_profile"]},
        %{"methods" => ["DELETE"], "path" => "^/profiles/me$", "scopes" => ["delete_profile"]}
      ]

      changeset =
        %Ecto.Changeset{changes: %{name: "acl", settings: %{"rules" => rules}}}
        |> Annon.Validators.Settings.validate_settings()

      assert [] == changeset.errors
    end

    test "Invalid settings" do
      rules = [
        %{"methods" => [], "path" => ".*", "scopes" => ["request_api"]}
      ]

      changeset =
        %Ecto.Changeset{changes: %{name: "acl", settings: %{"rules" => rules}}}
        |> Annon.Validators.Settings.validate_settings()

      refute [] == changeset.errors
    end
  end

  describe "Validator plugin validation" do
    test "Valid settings" do
      rules = [
        %{"methods" => ["POST", "PUT"], "path" => "*", "schema" => %{"some_field" => "some_value"}},
        %{"methods" => ["PUT"], "path" => "/profiles/me", "schema" => %{"some_field" => "some_value"}},
        %{"methods" => ["POST", "PUT"], "path" => "/profiles/me", "schema" => %{"some_field" => "some_value"}},
        %{"methods" => ["PATCH"], "path" => "/profiles/me", "schema" => %{"some_field" => "some_value"}}
      ]

      changeset =
        %Ecto.Changeset{changes: %{name: "validator", settings: %{"rules" => rules}}}
        |> Annon.Validators.Settings.validate_settings()

      assert [] == changeset.errors
    end

    test "Invalid settings" do
      rules = [
        %{"methods" => [], "path" => ".*", "schema" => %{"some_field" => "some_value"}}
      ]

      changeset =
        %Ecto.Changeset{changes: %{name: "validator", settings: %{"rules" => rules}}}
        |> Annon.Validators.Settings.validate_settings()

      refute [] == changeset.errors
    end
  end

  describe "Proxy plugin validation" do
    test "Invalid settings" do
      settings =
        %{"host" => "some-host.com", "path" => "not-good"}

      changeset =
        %Ecto.Changeset{changes: %{name: "proxy", settings: settings}}
        |> Annon.Validators.Settings.validate_settings()

      refute [] == changeset.errors
    end
  end
end
