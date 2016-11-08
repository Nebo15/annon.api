defmodule Gateway.Controllers.PluginTest do
  use Gateway.UnitCase
  alias Gateway.DB.Schemas.API, as: APISchema

  @plugin_url "/"

  test "GET /apis/:api_id" do
    api_model = Gateway.Factory.insert(:api_with_default_plugins)

    conn = "/#{api_model.id}/plugins"
    |> send_get()
    |> assert_conn_status()

    assert Enum.count(Poison.decode!(conn.resp_body)["data"]) == Enum.count(api_model.plugins)
  end

  test "GET /apis/:api_id/plugins/:name" do
    %{plugins: [p1, p2]} = api_model = Gateway.Factory.insert(:api_with_default_plugins)

    conn = "/#{api_model.id}/plugins/#{p1.name}"
    |> send_get()
    |> assert_conn_status()

    assert Poison.decode!(conn.resp_body)["data"]["settings"] == p1.settings

    conn = "/#{api_model.id}/plugins/#{p2.name}"
    |> send_get()
    |> assert_conn_status()

    assert Poison.decode!(conn.resp_body)["data"]["settings"] == p2.settings
  end

  test "POST /apis/:api_id/plugins" do
    api_model = Gateway.Factory.insert(:api)
    plugin_data = Gateway.Factory.build(:acl_plugin, api: api_model)

    conn = "/#{api_model.id}/plugins"
    |> send_data(plugin_data)
    |> assert_conn_status(201)

    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["name"] == plugin_data.name
    assert resp["settings"] == plugin_data.settings
  end

  test "PUT /apis/:api_id/plugins/:name" do
    p1 = Gateway.Factory.build(:jwt_plugin)
    api_model = Gateway.Factory.insert(:api, plugins: [p1])

    plugin_data = %{name: "validator", settings: %{"schema" => "{}"}}

    conn = "/#{api_model.id}/plugins/#{p1.name}"
    |> send_data(plugin_data, :put)
    |> assert_conn_status()

    resp = Poison.decode!(conn.resp_body)["data"]
    assert resp["name"] == plugin_data.name

    "/#{api_model.id}/plugins/validator"
    |> send_get()
    |> assert_conn_status()

    # Name can be read from uri params
    plugin_data = %{settings: %{"schema" => "{}"}}
    "/#{api_model.id}/plugins/validator"
    |> send_data(plugin_data, :put)
    |> assert_conn_status()

    plugin_data = %{name: "validator", settings: %{"schema" => "{}"}}
    conn = "/#{api_model.id}/plugins/validator"
    |> send_data(plugin_data, :put)
    |> assert_conn_status()

    resp = Poison.decode!(conn.resp_body)["data"]
    assert resp["settings"] == plugin_data.settings
  end

  test "DELETE /apis/:api_id" do
    %{plugins: [p1, p2]} = api_model = Gateway.Factory.insert(:api_with_default_plugins)

    "/#{api_model.id}/plugins/#{p1.name}"
    |> send_get()
    |> assert_conn_status()

    "/#{api_model.id}/plugins/#{p1.name}"
    |> send_delete()
    |> assert_conn_status()

    "/#{api_model.id}/plugins/#{p1.name}"
    |> send_get()
    |> assert_conn_status(404)

    "/#{api_model.id}/plugins/#{p2.name}"
    |> send_get()
    |> assert_conn_status()
  end

  def assert_conn_status(conn, code \\ 200) do
    assert code == conn.status
    conn
  end

  def send_get(path) do
    :get
    |> conn(path)
    |> prepare_conn
  end

  def send_delete(path) do
    :delete
    |> conn(path)
    |> prepare_conn
  end

  def send_data(path, data, method \\ :post) do
    method
    |> conn(path, Poison.encode!(data))
    |> prepare_conn
  end

  defp prepare_conn(conn) do
    conn
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.API.Plugins.call([])
  end
end
