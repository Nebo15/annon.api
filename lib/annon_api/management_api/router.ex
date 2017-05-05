defmodule Annon.ManagementAPI.Router do
  @moduledoc """
  Router for a [Annons Management API](http://docs.annon.apiary.io/#reference/apis).
  """
  use Plug.Router
  use Plug.ErrorHandler
  alias Annon.Helpers.Response
  alias Annon.ManagementAPI.Render

  if Confex.get(:annon_api, :sql_sandbox) do
    plug Phoenix.Ecto.SQL.Sandbox
  end

  plug :match

  plug Plug.RequestId
  plug Plug.Parsers, parsers: [:json],
                     pass: ["application/json"],
                     json_decoder: Poison

  plug :dispatch

  plug Annon.ManagementAPI.ConfigReloaderPlug,
    subscriber: &Annon.AutoClustering.reload_config/0

  forward "/apis", to: Annon.ManagementAPI.Controllers.API
  forward "/requests", to: Annon.ManagementAPI.Controllers.Request
  forward "/dictionaries", to: Annon.ManagementAPI.Controllers.Dictionaries

  get "/apis_status" do
    Annon.Configuration.API.list_disclosed_apis()
    |> Enum.map(fn %{id: id, name: name, description: description, docs_url: docs_url, health: health} ->
      %{id: id, name: name, description: description, docs_url: docs_url, health: health}
    end)
    |> Render.render_collection(conn)
  end

  match _ do
    Response.send_error(conn, :not_found)
  end

  def handle_errors(conn, error) do
    Response.send_error(conn, error)
  end
end
