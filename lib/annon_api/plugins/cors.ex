defmodule Annon.Plugins.CORS do
  @moduledoc """
  This plugin controls cross-origin resource sharing.
  """
  use Annon.Plugin, plugin_name: :cors

  defdelegate validate_settings(changeset), to: Annon.Plugins.CORS.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.CORS.SettingsValidator

  # TODO: If API does not expose OPTIONS requests won't hit here
  def execute(%Conn{} = conn, _request, settings) do
    settings = settings || %{}
    settings =
      settings
      |> Enum.map(fn
        {"origin", "*"} -> {:origin, "*"}
        {"origin", value} when is_binary(value) -> {:origin, Regex.compile!(value)}
        {key, value} -> {String.to_atom(key), value}
      end)
      |> CORSPlug.init()

    CORSPlug.call(conn, settings)
  end
end
