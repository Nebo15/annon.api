defmodule Gateway.Helpers.Render do
  @moduledoc """
  Use this helpers when you want to render result in a controllers.
  """
  import Gateway.Helpers.Response

  def render_collection(nil, conn) do
    conn
    |> send_error(:not_found)
  end

  def render_collection(resources, conn) when is_list(resources) do
    resources
    |> send(conn, 200)
  end

  def render_schema(nil, conn) do
    conn
    |> send_error(:not_found)
  end

  def render_schema(resource, conn) when is_map(resource) do
    resource
    |> send(conn, 200)
  end

  def render_change(tuple, conn, status \\ 200)

  def render_change(nil, conn, _status) do
    conn
    |> send_error(:not_found)
  end

  def render_change({:error, changeset}, conn, _status) do
    "422.json"
    |> EView.Views.ValidationError.render(%{changeset: changeset})
    |> send(conn, 422)
  end

  def render_change({:ok, resource}, conn, status) when is_map(resource) do
    resource
    |> send(conn, status)
  end

  def render_delete({0, _}, conn) do
    conn
    |> send_error(:not_found)
  end

  def render_delete({1, _}, conn) do
    %{}
    |> send(conn, 200)
  end
end
