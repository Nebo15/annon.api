defmodule Annon.ManagementAPI.Render do
  @moduledoc """
  Use this helpers when you want to render result in a controllers.
  """
  import Annon.Helpers.Response

  @doc """
  Renders collection with paging.
  """
  def render_collection_with_pagination({resources, %Ecto.Paging{} = paging}, conn) do
    conn = Plug.Conn.assign(conn, :paging, paging)
    render_collection(resources, conn)
  end

  @doc """
  Renders collection/
  """
  def render_collection(resources, conn) when is_list(resources) do
    send(resources, conn, 200)
  end

  @doc """
  Renders single schema.
  """
  def render_one(tuple, conn, status \\ 200)

  def render_one({:error, :not_found}, conn, _status) do
    send_error(conn, :not_found)
  end

  def render_one({:error, changeset}, conn, _status) do
    "422.json"
    |> EView.Views.ValidationError.render(%{changeset: changeset})
    |> send(conn, 422)
  end

  def render_one({:ok, resource}, conn, status) when is_map(resource) do
    send(resource, conn, status)
  end

  @doc """
  Renders http response without content.
  """
  def render_delete(conn) do
    Annon.Helpers.Response.send(conn, :no_content)
  end
end
