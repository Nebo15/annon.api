defmodule Gateway.HTTPHelpers.Response do # TODO: rename to Helpers.HTTPResponse
  @moduledoc """
  Gateway HTTP Helpers Response
  """
  def render_delete_response({:ok, _resource}, conn), do: render_response(%{}, conn, 200)
  def render_delete_response(_, conn), do: render_response(nil, conn)

  # TODO: rename to render()
  def render_response({:ok, resource}, conn, status \\ 200), do: render_response(resource, conn, status)
  def render_response({:error, changeset}, conn, _) do
    conn
    |> Plug.Conn.send_resp(422, Poison.encode!(EView.ValidationErrorView.render("422.json", changeset)))
  end
  def render_response(nil, conn, _), do: Plug.Conn.send_resp(conn, 404, Poison.encode!(%{}))
  def render_response(resource, conn, status) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(status, get_resp_body(resource))
  end

  def get_resp_body(resource) when is_list(resource), do: Poison.encode!(resource)
  def get_resp_body(resource) when is_map(resource), do: resource |> set_type() |> Poison.encode!()

  def set_type(resource) when resource != %{} do
    type = resource
    |> Map.get(:__struct__)
    |> EView.Renders.Data.extract_object_name

    resource
    |> Map.put(:type, type)
  end

  def set_type(resource), do: resource
end
