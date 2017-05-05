defmodule Annon.ManagementAPI.Controllers.DictionariesTest do
  @moduledoc false
  use Annon.ConnCase, async: true

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  test "lists all enabled plugins", %{conn: conn} do
    plugins =
      conn
      |> get("/dictionaries/plugins")
      |> json_response(200)
      |> Map.get("data")
      |> Enum.map(fn plugin -> plugin["name"] end)

    known_names = Application.get_env(:annon_api, :plugin_names)
    assert Enum.all?(known_names, fn name -> name in plugins end)
  end
end
