defmodule Annon.Plugins.SSL do
  @moduledoc """
  This plugin redirects insecure connections to HTTPS endpoint and setting HSTS headers.
  """
  use Annon.Plugin, plugin_name: :ssl

  def validate_settings(changeset),
    do: changeset

  def settings_validation_schema,
    do: %{}

  def prepare(%Request{} = request) do
    if Confex.get(:annon_api, :enable_ssl?) do
      setting = Confex.get_map(:annon_api, :ssl)
      %{request | plugins: Enum.map(request.plugins, fn
        %{name: :ssl} = plugin -> Map.put(plugin, "setting", setting)
        plugin -> plugin
      end)}
    else
      %{request | plugins: Enum.reject(request.plugins, fn plugin -> plugin.name == :ssl end)}
    end
  end

  def execute(%Conn{} = conn, _request, setting) do
    rewrite_on =
      setting
      |> Map.get(:rewrite_on, [])
      |> Enum.map(&String.to_atom/1)

    Plug.SSL.call(conn, {hsts_header(setting), {Annon.Plugins.SSL, :resolve_host, [conn, setting]}, rewrite_on})
  end

  defp hsts_header(setting) do
    if Map.get(setting, :hsts, true) do
      expires = Map.get(setting, :expires, 31_536_000)
      preload = Map.get(setting, :preload, false)
      subdomains = Map.get(setting, :subdomains, false)

      "max-age=#{expires}" <>
        if(preload, do: "; preload", else: "") <>
        if(subdomains, do: "; includeSubDomains", else: "")
    end
  end

  def resolve_host(%{host: host}, setting) do
    ssl_port =
      setting
      |> Keyword.fetch!(:redirect_port)
      |> to_string()

    host <> ":" <> ssl_port
  end
end
