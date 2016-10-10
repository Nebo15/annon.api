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

  get "/" do
    # List of items of the following form:
    #
    #   id
    #   name
    #   request
    #     scheme
    #     host
    #     port
    #     path
    #
    send_resp(conn, 200, "Getting a new API.")
  end

  get "/:id" do
    send_resp(conn, 200, "Getting a new API.")
  end

  post "/" do
    { code, resp } =
      case Gateway.DB.API.create(conn.body_params) do
        {:ok, api} ->
          responce_body = %{
            meta: %{
              code: 201
            },
            data: api
          }

          { 201, responce_body }
        {:error, changeset} ->
          IO.inspect changeset
          { 406, %{ sorry: "Nothing to create yet!" } }
          # reply with error
      end

    send_resp(conn, code, Poison.encode!(resp))
  end
end
