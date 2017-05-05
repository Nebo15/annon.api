defmodule Annon.ManagementAPI.RouterTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.ConfigurationFactory

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  test "lists all disclosed apis", %{conn: conn} do
    assert [] ==
      conn
      |> get("/apis_status")
      |> json_response(200)
      |> Map.get("data")

    api1 = ConfigurationFactory.insert(:api, disclose_status: true)
    api2 = ConfigurationFactory.insert(:api, disclose_status: true)

    apis =
      conn
      |> get("/apis_status")
      |> json_response(200)
      |> Map.get("data")

    assert apis == [
      %{
        "description" => api1.description,
        "docs_url" => api1.docs_url,
        "health" => api1.health,
        "id" => api1.id,
        "name" => api1.name
      },
      %{
        "description" => api2.description,
        "docs_url" => api2.docs_url,
        "health" => api2.health,
        "id" => api2.id,
        "name" => api2.name
      }
    ]
  end
end
