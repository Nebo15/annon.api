defmodule Gateway.HTTP.PluginTest do

  @plugin_url "/"

  use Gateway.HTTPTestHelper
  alias Gateway.DB.Models.API, as: APIModel

  test "GET /apis/:api_id" do
    data = get_api_model_data()
    {:ok, api_model} = APIModel.create(data)

    conn = "/#{api_model.id}/plugins"
    |> send_get()
    |> assert_conn_status()

    assert Enum.count(Poison.decode!(conn.resp_body)["data"]) == Enum.count(data.plugins)
  end

  test "GET /apis/:api_id/plugins/:name" do
    %{plugins: [p1, p2]} = data = get_api_model_data()
    {:ok, api_model} = APIModel.create(data)

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
    {:ok, api_model} = APIModel
    |> EctoFixtures.ecto_fixtures()
    |> APIModel.create()

    plugin_data = get_plugin_data(api_model.id)

    conn = "/#{api_model.id}/plugins"
    |> send_data(plugin_data)
    |> assert_conn_status(201)

    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["name"] == plugin_data.name
    assert resp["settings"] == plugin_data.settings
  end

  test "PUT /apis/:api_id/plugins/:name" do
    %{plugins: [p1, _]} = data = get_api_model_data()
    {:ok, api_model} = APIModel.create(Map.put(data, :plugins, [p1]))

    plugin_data = %{name: "Validator", settings: p1.settings}

    conn = "/#{api_model.id}/plugins/#{p1.name}"
    |> send_data(plugin_data, :put)
    |> assert_conn_status()

    resp = Poison.decode!(conn.resp_body)["data"]
    assert resp["name"] == plugin_data.name

    "/#{api_model.id}/plugins/Validator"
    |> send_get()
    |> assert_conn_status()

    plugin_data = %{name: "Validator", settings: %{"test" => "updated"}}
    conn = "/#{api_model.id}/plugins/Validator"
    |> send_data(plugin_data, :put)
    |> assert_conn_status()

    resp = Poison.decode!(conn.resp_body)["data"]
    assert resp["settings"] == plugin_data.settings
  end

  test "DELETE /apis/:api_id" do
    %{plugins: [p1, p2]} = data = get_api_model_data()
    {:ok, api_model} = APIModel.create(data)

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
    assert conn.status == code
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
