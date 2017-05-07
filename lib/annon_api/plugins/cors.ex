defmodule Annon.Plugins.CORS do
  @moduledoc """
  This plugin controls cross-origin resource sharing.
  """
  use Annon.Plugin, plugin_name: :cors

  def validate_settings(changeset),
    do: changeset

  def settings_validation_schema,
    do: %{}

  def execute(%Conn{} = conn, _request, settings) do
    settings = settings || %{}
    settings =
      settings
      |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)
      |> CORSPlug.init()

    CORSPlug.call(conn, settings)
  end
end
