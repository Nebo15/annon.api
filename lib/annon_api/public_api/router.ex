defmodule Annon.PublicRouter do
  @moduledoc """
  Router for a Annons public API.

  It has all available plugins assigned (in a specific order),
  but witch of them should process request will be resolved in run-time.
  """
  use Plug.Router

  if Confex.get(:annon_api, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  use Plug.ErrorHandler

  plug :match

  plug Plug.Head
  plug Plug.RequestId

  plug Plug.Parsers, parsers: [:multipart, :json],
                     pass: ["*/*"],
                     json_decoder: Poison,
                     length: 4_294_967_296,
                     read_length: 2_000_000,
                     read_timeout: 108_000

  plug Annon.Plugin.PipelinePlug

  plug :dispatch

  match _ do
    conn
    |> Annon.Helpers.Response.send_error(:not_found)
  end

  def handle_errors(%Plug.Conn{halted: false} = conn, error) do
    conn
    |> Annon.Helpers.Response.send_error(error)
  end
end
