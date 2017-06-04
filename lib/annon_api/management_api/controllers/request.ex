defmodule Annon.ManagementAPI.Controllers.Request do
  @moduledoc """
  REST interface that allows to fetch and delete stored requests.

  By-default, Annon will store all request and response structure in a persistent storage,
  and it's completely up to you how do you manage data retention in it.

  This data is used by Idempotency plug and by dashboard that shows near-realtime metrics on Annons perfomance.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/requests).
  """
  use Annon.ManagementAPI.ControllersRouter
  alias Annon.ManagementAPI.Pagination
  alias Annon.Requests.Log

  get "/" do
    paging = Pagination.page_info_from(conn.query_params)

    # TODO: Do not load whole data in list
    conn
    |> Map.fetch!(:query_params)
    |> Map.take(["idempotency_key", "api_ids", "status_codes", "ip_addresses"])
    |> Log.list_requests(paging)
    |> render_collection_with_pagination(conn)
  end

  get "/:request_id" do
    request_id
    |> Log.get_request()
    |> render_one(conn)
  end

  delete "/:request_id" do
    case Log.get_request(request_id) do
      {:ok, request} ->
        Log.delete_request(request)
        render_delete(conn)
      {:error, :not_found} ->
        render_delete(conn)
    end
  end
end
