defmodule Gateway.Controllers.API do
  @moduledoc """
  REST interface that allows to manage API's and their settings.

  API is a core entity that tells what host, port, path Annon should listen.
  After creating API you can assign plugins to it.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/apis).
  """
  use Gateway.Helpers.CommonRouter
  alias Gateway.DB.Schemas.API, as: APISchema
  alias Gateway.DB.Configs.Repo

  get "/" do
    APISchema
    |> Repo.page(page_info_from(conn.query_params))
    |> elem(0)
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

  forward "/", to: Gateway.Controllers.API.Plugin

  defp page_info_from(params) do
    starting_after = extract_integer(params, "ending_before")
    ending_before = extract_integer(params, "ending_before")
    limit = extract_integer(params, "limit")

    cursors = %Ecto.Paging.Cursors{starting_after: starting_after, ending_before: ending_before}

    %Ecto.Paging{limit: limit, cursors: cursors}
    |> IO.inspect
  end

  defp extract_integer(map, key) do
    case Map.get(map, key) do
      nil ->
        nil
      string ->
        string
        |> Integer.parse
        |> elem(0)
    end
  end
end
