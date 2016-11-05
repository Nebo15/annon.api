defmodule Gateway.Helpers.Response do
  @moduledoc """
  This is a helper module for dispatching requests.
  """

  def send_error(conn, :not_found) do
    "404.json"
    |> send_error_template(conn, 404)
  end

  def send_error(conn, :internal_error) do
    "501.json"
    |> send_error_template(conn, 501)
  end

  def send_error(conn, %{kind: kind, reason: reason, stack: _stack}) do
    status = get_exception_status(kind, reason)

    status
    |> to_string()
    |> Kernel.<>(".json")
    |> send_error_template(conn, status)
  end

  def send(resource, conn, status) do
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

  defp send_error_template(template, conn, status) do
    template
    |> EView.Views.Error.render()
    |> send(conn, status)
  end

  defp get_exception_status(:throw, _throw), do: 500
  defp get_exception_status(:exit, _exit), do: 500
  defp get_exception_status(:error, error), do: Plug.Exception.status(error)
end
