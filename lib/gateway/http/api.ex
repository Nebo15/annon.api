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
    apis = Gateway.DB.Repo.all(Gateway.DB.API)

    responce_body = %{
      meta: %{
        code: 200
      },
      data: apis
    }

    send_resp(conn, 200, Poison.encode!(responce_body))
  end

  get "/:api_id" do
    { code, resp } =
      case Gateway.DB.Repo.get(Gateway.DB.API, api_id) do
        nil ->
          response_body = %{
            meta: %{
              code: 404,
              description: "The requested API doesn’t exist."
            }
          }

          { 404, response_body }
        api ->
          responce_body = %{
            meta: %{
              code: 200
            },
            data: api
          }

          { 200, responce_body }
      end

    send_resp(conn, code, Poison.encode!(resp))
  end

  post "/" do
    { code, resp } =
      case Gateway.DB.API.create(conn.body_params) do
        {:ok, api} ->
          response_body = %{
            meta: %{
              code: 201
            },
            data: api
          }

          { 201, response_body }
        {:error, changeset} ->
          errors =
            for {field, {error, _}} <- changeset.changes.request.errors, into: %{} do
              {to_string(field), error}
            end

          response_body = %{
            meta: %{
              code: 422,
              description: "Validation errors",
              errors: errors
            }
          }

          { 422, response_body }
      end

    send_resp(conn, code, Poison.encode!(resp))
  end
end
