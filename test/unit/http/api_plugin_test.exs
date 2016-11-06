defmodule Gateway.HTTP.PluginTest do

  @plugin_url "/"

  use Gateway.UnitCase
  alias Gateway.DB.Schemas.API, as: APISchema

  test "GET /apis/:api_id" do
    data = get_api_model_data()
    {:ok, api_model} = APISchema.create(data)

    conn = "/#{api_model.id}/plugins"
    |> send_get()
    |> assert_conn_status()

    assert Enum.count(Poison.decode!(conn.resp_body)["data"]) == Enum.count(data.plugins)
  end

  test "GET /apis/:api_id/plugins/:name" do
    %{plugins: [p1, p2]} = data = get_api_model_data()
    {:ok, api_model} = APISchema.create(data)

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
    {:ok, api_model} = APISchema
    |> EctoFixtures.ecto_fixtures()
    |> APISchema.create()

    plugin_data = get_plugin_data(api_model.id, "acl")

    conn = "/#{api_model.id}/plugins"
    |> send_data(plugin_data)
    |> assert_conn_status(201)

    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["name"] == plugin_data.name
    assert resp["settings"] == plugin_data.settings
  end

  test "PUT /apis/:api_id/plugins/:name" do
    %{plugins: [p1, _]} = data = get_api_model_data()
    {:ok, api_model} = APISchema.create(Map.put(data, :plugins, [p1]))

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
    %{plugins: [p1, p2]} = data = get_api_model_data()
    {:ok, api_model} = APISchema.create(data)

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
    |> Gateway.HTTP.API.Plugins.call([])
  end
end
