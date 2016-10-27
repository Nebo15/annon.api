defmodule Gateway.HTTP.Requests do
  @moduledoc """
  REST API to get Requests logs data
  Documentation http://docs.osapigateway.apiary.io/#reference/requests
  """
  use Gateway.Helpers.CommonRouter
  alias Gateway.Logger.DB.Models.LogRecord
  alias Gateway.Utils.ModelToMap

  get "/" do
    records = LogRecord.get_records

    records
    |> ModelToMap.convert
    |> render_show_response
    |> send_response(conn)
  end

  get "/:request_id" do
    result = LogRecord.get_record_by([id: request_id])
    
    result
    |> ModelToMap.convert
    |> render_request
    |> send_response(conn)
  end

  delete "/:request_id" do
    LogRecord.delete(%{id: request_id})
    {:ok, %{}}
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
