defmodule Gateway.Changeset.SettingsValidator do
  @moduledoc """
    Changeset validator for Plugin settings
  """
  alias Ecto.Changeset
  import Ecto.Changeset

  # JWT
  def validate_settings(%Changeset{changes: %{name: :jwt, settings: settings}} = ch) do
    {%{}, %{signature: :string}}
    |> cast(settings, [:signature])
    |> validate_required([:signature])
    |> put_changeset_errors(ch)
  end

  # ACL
  def validate_settings(%Changeset{changes: %{name: :acl, settings: settings}} = ch) do
    {%{}, %{scope: :string}}
    |> cast(settings, [:scope])
    |> validate_required([:scope])
    |> put_changeset_errors(ch)
  end

  # Validator
  def validate_settings(%Changeset{changes: %{name: :validator, settings: settings}} = ch) do
    {%{}, %{schema: :string}}
    |> cast(settings, [:schema])
    |> validate_required([:schema])
    |> validate_json(:schema)
    |> put_changeset_errors(ch)
  end

  # IPRestriction
  def validate_settings(%Changeset{changes: %{name: :ip_restriction, settings: settings}} = ch) do
    {%{}, %{ip_whitelist: :string, ip_blacklist: :string}}
    |> cast(settings, [:ip_blacklist, :ip_whitelist])
    |> validate_ip_list(:ip_whitelist)
    |> validate_ip_list(:ip_blacklist)
    |> put_changeset_errors(ch)
  end

  # Proxy
  def validate_settings(%Changeset{changes: %{name: :proxy, settings: settings}} = ch) do
    {%{}, %{scheme: :string, host: :string, port: :integer, path: :string, method: :string}}
    |> cast(settings, [:scheme, :host, :port, :path, :method])
    |> validate_required([:host])
    |> validate_format(:scheme, ~r/^(http|https)$/)
    |> put_changeset_errors(ch)
  end

  # general
  def validate_settings(ch), do: ch

  # helpers
  defp validate_json(%Changeset{} = ch, field) do
    ch
    |> get_field(field, "")
    |> Poison.decode()
    |> validate_json(ch)
  end
  defp validate_json({:ok, _}, ch), do: ch
  defp validate_json({:error, _}, ch) do
    add_error(ch, :settings, "Validator.settings: field 'schema' is invalid json", [validation: :json, json: []])
  end

  defp validate_ip_list(%Changeset{} = ch, field) do
    ch
    |> get_field(field, "")
    |> String.split(",")
    |> Enum.reduce_while(ch, fn(ip, acc) ->
      ip
      |> ip_valid?()
      |> put_ip_error(acc, field)
     end)
  end

  def ip_valid?(ip) do
    ~r/^(?:(?:\*|25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:\*|25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
    |> Regex.match?(ip)
  end

  defp put_ip_error(true, ch, _name), do: {:cont, ch}
  defp put_ip_error(false, ch, name) do
    {:halt, add_error(ch,
                      :settings,
                      "IPRestriction.settings field '#{name}' must contain valid ip addresses",
                      [validation: :format, format: []]
                      )}
  end

  defp put_changeset_errors(%Changeset{valid?: true}, ch), do: ch
  defp put_changeset_errors(%Changeset{valid?: false, errors: errors}, ch) do
    ch
    |> Map.merge(%{errors: errors, valid?: false})
  end
end
