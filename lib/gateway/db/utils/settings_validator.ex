defmodule Gateway.Changeset.SettingsValidator do
  @moduledoc """
    Changeset validator for Plugin settings
  """
  alias Ecto.Changeset
  import Ecto.Changeset

  # JWT
  def validate_settings(%Changeset{changes: %{name: :JWT, settings: %{"signature" => s}}} = ch) when is_binary(s) do
    ch
  end
  def validate_settings(%Changeset{changes: %{name: :JWT, settings: %{"signature" => _}}} = ch) do
    add_error(ch, :settings, "JWT.settings field 'signature' must be a string")
  end
  def validate_settings(%Changeset{changes: %{name: :JWT}} = ch) do
    add_error(ch, :settings, "JWT.settings required field 'signature'")
  end

  # Validator
  def validate_settings(%Changeset{changes: %{name: :Validator, settings: %{"schema" => s}}} = ch) when is_binary(s) do
    s
    |> Poison.decode()
    |> validate_json_schema(ch)
  end
  def validate_settings(%Changeset{changes: %{name: :Validator, settings: %{"schema" => _}}} = ch) do
    add_error(ch, :settings, "Validator.settings field 'schema' must be a string")
  end
  def validate_settings(%Changeset{changes: %{name: :Validator}} = ch) do
    add_error(ch, :settings, "Validator.settings field 'schema' is required")
  end

  # ACL
  def validate_settings(%Changeset{changes: %{name: :ACL, settings: %{"scope" => s}}} = ch) when is_binary(s) do
    ch
  end
  def validate_settings(%Changeset{changes: %{name: :ACL, settings: %{"scope" => _}}} = ch) do
    add_error(ch, :settings, "ACL.settings field 'scope' must be a string")
  end
  def validate_settings(%Changeset{changes: %{name: :ACL}} = ch) do
    add_error(ch, :settings, "ACL.settings required field 'scope'")
  end

  # IPRestriction
  def validate_settings(%Changeset{changes:
    %{name: :IPRestriction, settings: %{"ip_whitelist" => w, "ip_blacklist" => b}}} = ch)
    when is_binary(w) and is_binary(b) do
    ch
    |> validate_ip_list(Poison.decode(w), "ip_whitelist")
    |> validate_ip_list(Poison.decode(b), "ip_blacklist")
  end
  def validate_settings(%Changeset{changes: %{name: :IPRestriction}} = ch) do
    add_error(ch, :settings, "IPRestriction.settings required string fields 'ip_whitelist' and 'ip_blacklist'")
  end

  # Proxy
  def validate_settings(%Changeset{changes: %{name: :Proxy, settings: %{"scope" => s}}} = ch) when is_binary(s) do
    ch
  end
  def validate_settings(%Changeset{changes: %{name: :Proxy, settings: %{"scope" => _}}} = ch) do
    add_error(ch, :settings, "ACL.settings field 'scope' must be a string")
  end
  def validate_settings(%Changeset{changes: %{name: :Proxy}} = ch) do
    add_error(ch, :settings, "ACL.settings required field 'scope'")
  end

  # general
  def validate_settings(ch), do: ch

  # helpers
  defp validate_json_schema({:ok, _}, ch), do: ch
  defp validate_json_schema({:error, _}, ch) do
    add_error(ch, :settings, "Validator.settings: field 'schema' is invalid json")
  end

  defp validate_ip_list(ch, {:ok, list}, name) when is_list(list) do
    list
    |> Enum.reduce_while(ch, fn(ip, acc) ->
      ip
      |> ip_valid?()
      |> put_ip_error(acc, name)
     end)
  end
  defp validate_ip_list(ch, {:ok, _}, name) do
    add_error(ch, :settings, "IPRestriction.settings field '#{name}' must be a valid JSON list")
  end
  defp validate_ip_list(ch, {:error, _}, name) do
    add_error(ch, :settings, "IPRestriction.settings field '#{name}' must be a valid JSON list")
  end

  defp put_ip_error(false, ch, name) do
    ch = ch
    |> add_error(:settings, "IPRestriction.settings field '#{name}' must contain valid ip addresses")
    {:halt, ch}
  end
  defp put_ip_error(true, ch, _name) do
    {:cont, ch}
  end

  def ip_valid?(ip) do
    Regex.match?(~r/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/, ip)
  end
end
