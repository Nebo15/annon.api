defmodule Annon.ManagementAPI.Controllers.Request do
  @moduledoc """
  REST interface that allows to fetch and delete stored requests.

  By-default, Annon will store all request and response structure in a persistent storage,
  and it's completely up to you how do you manage data retention in it.

  This data is used by Idempotency plug and by dashboard that shows near-realtime metrics on Annons perfomance.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/requests).
  """
  use Annon.ManagementAPI.CommonRouter
  alias Annon.Logger.Repo
  alias Annon.Logger.LogEntry, as: LogSchema
  alias Annon.Helpers.Pagination

  get "/" do
    LogSchema
    |> Repo.page(Pagination.page_info_from(conn.query_params))
    |> elem(0)
    |> render_collection(conn)
  end

  get "/:request_id" do
    [id: request_id]
    |> LogSchema.get_one_by()
    |> render_schema(conn)
  end

  delete "/:request_id" do
    request_id
    |> LogSchema.delete()
    |> render_delete(conn)
  end
end
