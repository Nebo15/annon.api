defmodule Annon.Validators.Settings do
  @moduledoc """
  This module provides helpers to validate individual plugin settings via JSON Schema that is stored inside methods.
  """
  alias Ecto.Changeset

  # JWT
  def validate_settings(%Changeset{changes: %{name: "jwt"}} = ch) do
    Annon.Plugins.JWT.SettingsValidator.validate_settings(ch)
  end

  # ACL
  def validate_settings(%Changeset{changes: %{name: "acl"}} = ch) do
    Annon.Plugins.ACL.SettingsValidator.validate_settings(ch)
  end

  # Validator
  def validate_settings(%Changeset{changes: %{name: "validator"}} = ch) do
    Annon.Plugins.Validator.SettingsValidator.validate_settings(ch)
  end

  # IPRestriction
  def validate_settings(%Changeset{changes: %{name: "ip_restriction"}} = ch) do
    Annon.Plugins.IPRestriction.SettingsValidator.validate_settings(ch)
  end

  # UARestriction
  def validate_settings(%Changeset{changes: %{name: "ua_restriction"}} = ch) do
    Annon.Plugins.UARestriction.SettingsValidator.validate_settings(ch)
  end

  # Proxy
  def validate_settings(%Changeset{changes: %{name: "proxy"}} = ch) do
    Annon.Plugins.Proxy.SettingsValidator.validate_settings(ch)
  end

  # Scopes
  def validate_settings(%Changeset{changes: %{name: "scopes"}} = ch) do
    Annon.Plugins.Scopes.SettingsValidator.validate_settings(ch)
  end

  # general
  def validate_settings(ch), do: ch
end
