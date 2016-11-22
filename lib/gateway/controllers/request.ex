defmodule Gateway.Controllers.Request do
  @moduledoc """
  REST interface that allows to fetch and delete stored requests.

  By-default, Annon will store all request and response structure in a persistent storage,
  and it's completely up to you how do you manage data retention in it.

  This data is used by Idempotency plug and by dashboard that shows near-realtime metrics on Annons perfomance.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/requests).
  """
  use Gateway.Helpers.CommonRouter
  alias Gateway.DB.Logger.Repo
  alias Gateway.DB.Schemas.Log, as: LogSchema

  get "/" do
    LogSchema
    |> Repo.all
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
