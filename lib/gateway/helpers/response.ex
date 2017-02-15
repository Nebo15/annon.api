defmodule Gateway.Helpers.Response do
  @moduledoc """
  This is a helper module for dispatching requests.

  It's used by `Gateway.Helpers.Render` helpers and places where we want to return an error.
  """

  @doc """
  Send error by a [EView.ErrorView](https://github.com/Nebo15/eview/blob/master/lib/eview/views/error_view.ex)
  template to a API consumer and halt connection.
  """
  def send_error(conn, :not_found) do
    "404.json"
    |> send_error_template(conn, 404)
  end

  def send_error(conn, :internal_error) do
    "501.json"
    |> send_error_template(conn, 501)
  end

  # This method is used in Plug.ErrorHandler.
  def send_error(conn, %{kind: kind, reason: reason, stack: _stack}) do
    status = get_exception_status(kind, reason)

    status
    |> to_string()
    |> Kernel.<>(".json")
    |> send_error_template(conn, status)
  end

  def send_validation_error(conn, invalid) do
    "422.json"
    |> EView.Views.ValidationError.render(%{schema: invalid})
    |> send(conn, 422)
    |> halt()
  end

  @doc """
  Send request to a API consumer.

  You may need to halt connection after calling it,
  if you want to stop rest of plugins from processing rests.
  """
  def send(resource, conn, status) do
    conn = conn
    |> Plug.Conn.put_status(status)
    |> Plug.Conn.put_resp_content_type("application/json")

    body = resource
    |> EView.wrap_body(conn)
    |> Poison.encode!()

    conn
    |> Plug.Conn.send_resp(status, body)
  end

  def build_upstream_error(reason) do
    "500.json"
    |> EView.Views.Error.render(%{
      type: :upstream_error, 
      message: "Upstream is unavailable with reason #{inspect reason}"
    })
    |> Poison.encode!()
  end

  @doc """
  Halt the connection.

  Delegates to a `Plug.Conn.halt/1` function.
  """
  def halt(conn), do: conn |> Plug.Conn.halt()

  defp send_error_template(template, conn, status) do
    template
    |> EView.Views.Error.render()
    |> send(conn, status)
    |> halt()
  end

  defp get_exception_status(:throw, _throw), do: 500
  defp get_exception_status(:exit, _exit), do: 500
  defp get_exception_status(:error, error), do: Plug.Exception.status(error)
end
