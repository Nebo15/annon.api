defmodule Gateway.Changeset.Validator.SettingsTest do
  use Gateway.API.ModelCase

  describe "ACL plugin validation" do
    test "Valid settings" do
      rules = [
        %{"methods" => ["GET", "POST", "PUT", "DELETE"], "path" => "*", "scopes" => ["request_api"]},
        %{"methods" => ["GET"], "path" => "/profiles/me", "scopes" => ["read_profile"]},
        %{"methods" => ["POST", "PUT"], "path" => "/profiles/me", "scopes" => ["update_profile"]},
        %{"methods" => ["DELETE"], "path" => "/profiles/me", "scopes" => ["delete_profile"]}
      ]

      changeset =
        %Ecto.Changeset{changes: %{name: "acl", settings: %{"rules" => rules}}}
        |> Gateway.Changeset.Validator.Settings.validate_settings()

      assert [] == changeset.errors
    end

    test "Invalid settings" do
      rules = [
        %{"methods" => [], "path" => ".*", "scopes" => ["request_api"]}
      ]

      changeset =
        %Ecto.Changeset{changes: %{name: "acl", settings: %{"rules" => rules}}}
        |> Gateway.Changeset.Validator.Settings.validate_settings()

      refute [] == changeset.errors
    end
  end
end