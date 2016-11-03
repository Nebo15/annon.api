defmodule Gateway.HTTPHelpers.Response do # TODO: rename to Helpers.HTTPResponse
  @moduledoc """
  Gateway HTTP Helpers Response
  """
  def render_delete_response({:ok, _resource}, conn), do: render_response(%{}, conn, 200)
  def render_delete_response(_, conn), do: render_response(nil, conn)

  # TODO: rename to render()
  def render_response({:ok, resource}, conn, status \\ 200), do: render_response(resource, conn, status)
  def render_response({:error, changeset}, conn, _) do
    "422.json"
    |> EView.Views.ValidationError.render(%{changeset: changeset})
    |> render_response(conn, 422)
  end
  def render_response(nil, conn, status) do
    "404.json"
    |> EView.Views.Error.render()
    |> render_response(conn, 404)
  end
  def render_response(resource, conn, status) do
    conn = conn
    |> Plug.Conn.put_status(status)

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, get_resp_body(resource, conn))
  end

  def get_resp_body(resource, conn), do: resource |> EView.wrap_body(conn) |> Poison.encode!()
end
