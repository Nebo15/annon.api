defmodule Gateway.Helpers.Response do
  @moduledoc """
  This is a helper module for dispatching requests.
  """

  def send_and_halt(resource, conn, status) do
    conn = conn
    |> Plug.Conn.put_status(status)
    |> Plug.Conn.put_resp_content_type("application/json")

    body = resource
    |> EView.wrap_body(conn)
    |> Poison.encode!()

    conn
    |> Plug.Conn.send_resp(status, body)
    |> Plug.Conn.halt()
  end

  def render_and_halt(template, conn, status) do
    template
    |> EView.Views.Error.render()
    |> send_and_halt(conn, status)
  end

  def send_not_found_error(conn) do
    "404.json"
    |> render_and_halt(conn, 404)
  end

  def send_internal_error(conn, %{kind: kind, reason: reason, stack: _stack}) do
    status = status(kind, reason)

    status
    |> to_string()
    |> Kernel.<>(".json")
    |> render_and_halt(conn, status)
  end

  def send_internal_error(conn) do
    "501.json"
    |> render_and_halt(conn, 501)
  end

  defp status(:throw, _throw), do: 500
  defp status(:exit, _exit), do: 500
  defp status(:error, error), do: Plug.Exception.status(error)

  # TODO: refactor belove this line
  def render_delete_response({:ok, _resource}, conn), do: render_response(%{}, conn, 200)
  def render_delete_response(_, conn), do: render_response(nil, conn)

  # TODO: rename to render()
  def render_response({:ok, resource}, conn, status \\ 200), do: render_response(resource, conn, status)
  def render_response({:error, changeset}, conn, _) do
    "422.json"
    |> EView.Views.ValidationError.render(%{changeset: changeset})
    |> render_response(conn, 422)
  end
  def render_response(nil, conn, _status) do
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
