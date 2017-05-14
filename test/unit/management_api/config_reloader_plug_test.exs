defmodule Annon.ManagementAPI.ConfigReloaderPlugTest do
  @moduledoc false
  use Annon.ConnCase, async: false
  import ExUnit.CaptureLog
  alias Annon.Factories.Configuration, as: ConfigurationFactory

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  test "reloads the config cache if api is created", %{conn: conn} do
    id = Ecto.UUID.generate()
    attrs = ConfigurationFactory.params_for(:api, id: id)
    ConfigurationFactory.insert(:proxy_plugin, api_id: id)

    update_config = fn ->
      conn
      |> put_json(api_path(id), attrs)
      |> json_response(201)
    end

    assert capture_log(update_config) =~ "config cache was warmed up"
  end

  test "reloads the config cache if api is updated", %{conn: conn} do
    api = ConfigurationFactory.insert(:api)
    attrs = ConfigurationFactory.params_for(:api, name: "New name")
    ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

    update_config = fn ->
      conn
      |> put_json(api_path(api.id), attrs)
      |> json_response(200)
    end

    assert capture_log(update_config) =~ "config cache was warmed up"
  end

  test "reloads the config cache if api is deleted", %{conn: conn} do
    update_config =
      fn ->
        resp =
          conn
          |> delete(api_path(Ecto.UUID.generate()))
          |> response(204)

        assert "" = resp
      end

    assert capture_log(update_config) =~ "config cache was warmed up"
  end

  test "reloads the config cache if plugin is created or updated", %{conn: conn} do
    api = ConfigurationFactory.insert(:api)
    attrs = ConfigurationFactory.params_for(:proxy_plugin)

    update_config = fn ->
      conn
      |> put_json(plugin_path(api.id, attrs.name), attrs)
      |> json_response(201)
    end

    assert capture_log(update_config) =~ "config cache was warmed up"

    attrs = ConfigurationFactory.params_for(:proxy_plugin, is_enabled: false)

    update_config = fn ->
      conn
      |> put_json(plugin_path(api.id, attrs.name), attrs)
      |> json_response(200)
    end

    assert capture_log(update_config) =~ "config cache was warmed up"
  end

  test "reloads the config cache if plugin is deleted", %{conn: conn} do
    api = ConfigurationFactory.insert(:api)
    plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

    update_config =
      fn ->
        conn
        |> delete(plugin_path(api.id, plugin.name))
        |> response(204)
      end

    assert capture_log(update_config) =~ "config cache was warmed up"
  end
end
