defmodule Annon.Helpers.Conn do
  @moduledoc """
  Connection helpers.
  """
  import Plug.Conn

  def get_request_id(conn, default) do
    case get_resp_header(conn, "x-request-id") do
      [] -> default
      [id | _] -> id
    end
  end

  def get_idempotency_key(conn, default) do
    case get_resp_header(conn, "x-idempotency-key") do
      [] -> default
      [idempotency_key | _] -> idempotency_key
    end
  end

  def fetch_idempotency_key(conn) do
    case get_resp_header(conn, "x-idempotency-key") do
      [] -> :error
      [idempotency_key | _] -> {:ok, idempotency_key}
    end
  end

  def get_content_length(conn, default) do
    case get_resp_header(conn, "content-length") do
      [] -> default
      [id | _] -> id
    end
  end

  def get_conn_status(%{status: nil}, default),
    do: default
  def get_conn_status(%{status: status}, _default),
    do: status
end
