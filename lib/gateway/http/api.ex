defmodule Gateway.HTTP.API do
  @moduledoc """
  REST for api
  Documentation http://docs.osapigateway.apiary.io/#reference/apis
  """
  use Plug.Router

  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison

  plug :match
  plug :dispatch

  import Gateway.HTTPHelpers.Response

  get "/" do
    apis = Gateway.DB.Repo.all(Gateway.DB.API)

    { code, resp } =
      render_show_response(apis)

    send_resp(conn, code, resp)
  end

  get "/:api_id" do
    { code, resp } =
      case Gateway.DB.Repo.get(Gateway.DB.API, api_id) do
        nil ->
          render_not_found_response()
        api ->
          render_show_response(api)
      end

    send_resp(conn, code, resp)
  end

  post "/" do
    { code, resp } =
      case Gateway.DB.API.create(conn.body_params) do
        {:ok, api} ->
          render_create_response(api)
        {:error, changeset} ->
          render_errors_response(changeset)
      end

    send_resp(conn, code, resp)
  end
end
