defmodule Annon.ManagementAPI.Controllers.API do
  @moduledoc """
  REST interface that allows to manage API's and their settings.

  API is a core entity that tells what host, port, path Annon should listen.
  After creating API you can assign plugins to it.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/apis).
  """
  use Annon.ManagementAPI.ControllersRouter
  alias Annon.Configuration.API, as: ConfigurationAPI
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias Annon.Helpers.Pagination

  get "/" do
    paging = Pagination.page_info_from(conn.query_params)

    conn
    |> Map.fetch!(:query_params)
    |> Map.take(["name"])
    |> ConfigurationAPI.list_apis(paging)
    |> render_collection_with_pagination(conn)
  end

  get "/:api_id" do
    api_id
    |> ConfigurationAPI.get_api()
    |> render_one(conn)
  end

  put "/:api_id" do
    case ConfigurationAPI.get_api(api_id) do
      {:ok, %APISchema{} = api} ->
        api
        |> ConfigurationAPI.update_api(conn.body_params)
        |> render_one(conn, 200)

      {:error, :not_found} ->
        api_id
        |> ConfigurationAPI.create_api(conn.body_params)
        |> render_one(conn, 201)
    end
  end

  # TODO: deprecated
  post "/" do
    Ecto.UUID.generate()
    |> ConfigurationAPI.create_api(conn.body_params)
    |> render_one(conn, 201)
  end

  delete "/:api_id" do
    case ConfigurationAPI.get_api(api_id) do
      {:ok, api} ->
        ConfigurationAPI.delete_api(api)
        render_delete(conn)
      {:error, :not_found} ->
        render_delete(conn)
    end
  end

  forward "/", to: Annon.ManagementAPI.Controllers.APIPlugin
end
