# TODO: move to plugins tests
defmodule Annon.Validators.SettingsTest do
  use ExUnit.Case, async: true

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
        |> Annon.Plugins.Validator.SettingsValidator.validate_settings()

      assert [] == changeset.errors
    end

    test "Invalid settings" do
      rules = [
        %{"methods" => [], "path" => ".*", "schema" => %{"some_field" => "some_value"}}
      ]

      changeset =
        %Ecto.Changeset{changes: %{name: "validator", settings: %{"rules" => rules}}}
        |> Annon.Plugins.Validator.SettingsValidator.validate_settings()

      refute [] == changeset.errors
    end
  end

  describe "Proxy plugin validation" do
    test "Invalid settings" do
      settings =
        %{"host" => "some-host.com", "path" => "not-good"}

      changeset =
        %Ecto.Changeset{changes: %{name: "proxy", settings: settings}}
        |> Annon.Plugins.Proxy.SettingsValidator.validate_settings()

      refute [] == changeset.errors
    end
  end
end
