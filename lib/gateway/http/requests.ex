defmodule Gateway.HTTP.Requests do
  @moduledoc """
  REST for Requests
  Documentation http://docs.osapigateway.apiary.io/#reference/requests
  """
  use Gateway.Helpers.CommonRouter
  alias Gateway.DB.Models.Log

  get "/" do
    # ToDo: pagination
    conn
    |> get_limit()
    |> Log.get_records()
    |> render_show_response
    |> send_response(conn)
  end

  get "/:request_id" do
    result = Log.get_record_by([id: request_id])

    result
    |> render_request
    |> send_response(conn)
  end

  delete "/:request_id" do
    request_id
    |> Log.delete()
    |> render_delete_response
    |> send_response(conn)
  end

  defp get_limit(conn) do
    limit = conn.params["limit"] || 50
    limit
    |> to_string
    |> String.to_integer
  end

  def render_request(nil), do: render_not_found_response("Request not found")
  def render_request(request), do: render_show_response(request)

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end
end
