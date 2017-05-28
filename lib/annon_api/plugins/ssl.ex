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
      settings = Confex.get_map(:annon_api, :ssl)
      %{request | plugins: Enum.map(request.plugins, fn
        %{name: :ssl} = plugin -> Map.put(plugin, :settings, settings)
        plugin -> plugin
      end)}
    else
      %{request | plugins: Enum.reject(request.plugins, fn plugin -> plugin.name == :ssl end)}
    end
  end

  def execute(%Conn{} = conn, _request, settings) do
    rewrite_on =
      settings
      |> Keyword.get(:rewrite_on, [])
      |> Enum.map(&String.to_atom/1)

    Plug.SSL.call(conn, {hsts_header(settings), {Annon.Plugins.SSL, :resolve_host, [conn, settings]}, rewrite_on})
  end

  defp hsts_header(settings) do
    if Keyword.get(settings, :hsts, true) do
      expires = Keyword.get(settings, :expires, 31_536_000)
      preload = Keyword.get(settings, :preload, false)
      subdomains = Keyword.get(settings, :subdomains, false)

      "max-age=#{expires}" <>
        if(preload, do: "; preload", else: "") <>
        if(subdomains, do: "; includeSubDomains", else: "")
    end
  end

  def resolve_host(%{host: host}, settings) do
    ssl_port =
      settings
      |> Keyword.fetch!(:redirect_port)
      |> to_string()

    host <> ":" <> ssl_port
  end
end
