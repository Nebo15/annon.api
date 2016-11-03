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
    |> render_response(conn)
  end

  get "/:request_id" do
    [id: request_id]
    |> Log.get_by()
    |> render_response(conn)
  end

  delete "/:request_id" do
    request_id
    |> Log.delete()
    |> render_delete_response(conn)
  end

  defp get_limit(conn) do
    limit = conn.params["limit"] || 50
    limit
    |> to_string
    |> String.to_integer
  end
end
