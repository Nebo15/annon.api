defmodule Annon.Controllers.API do
  @moduledoc """
  REST interface that allows to manage API's and their settings.

  API is a core entity that tells what host, port, path Annon should listen.
  After creating API you can assign plugins to it.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/apis).
  """
  use Annon.Helpers.CommonRouter
  alias Annon.DB.Schemas.API, as: APISchema
  alias Annon.DB.Configs.Repo
  alias Annon.Helpers.Pagination

  get "/" do
    APISchema
    |> Repo.page(Pagination.page_info(conn))
    |> render_collection(conn)
  end

  get "/:api_id" do
    APISchema
    |> Repo.get(api_id)
    |> render_schema(conn)
  end

  put "/:api_id" do
    api_id
    |> APISchema.update(conn.body_params)
    |> render_change(conn)
  end

  post "/" do
    conn.body_params
    |> APISchema.create
    |> render_change(conn, 201)
  end

  delete "/:api_id" do
    api_id
    |> APISchema.delete
    |> render_delete(conn)
  end

  forward "/", to: Annon.Controllers.API.Plugin
end
