defmodule Gateway.Helpers.HTTP.Errors do
  @moduledoc """
  This module is used to catch failures and render them using a view.
  """

  def send_not_found_error(conn) do
    render_and_halt("404.json", conn, 404)
  end

  def send_validation_error(conn, changeset) do
    "422.json"
    |> EView.Views.ValidationError.render(%{changeset: changeset})
    |> send_and_halt(conn, 422)
  end

  def send_internal_error(conn, %{kind: kind, reason: reason, stack: _stack}) do
    status = status(kind, reason)

    status
    |> to_string()
    |> Kernel.<>(".json")
    |> render_and_halt(conn, status)
  end

  defp render_and_halt(template, conn, status) do
    template
    |> EView.Views.Error.render()
    |> send_and_halt(conn, status)
  end

  defp send_and_halt(body, conn, status) do
    body
    |> Gateway.HTTPHelpers.Response.render_response(conn, status)
    |> Plug.Conn.halt()
  end

  defp status(:throw, _throw), do: 500
  defp status(:exit, _exit), do: 500
  defp status(:error, error), do: Plug.Exception.status(error)
end
