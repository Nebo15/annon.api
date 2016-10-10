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
    # Expects a JSON as such:
    #
    # {
    #   "id": "56c31536a60ad644060041af",
    #   "name": "my_api",
    #   "request": {
    #     "scheme": "http",
    #     "host": "example.com",
    #     "port": 80,
    #     "path": "/example_api/v1/"
    #   }
    # }
    #

    IO.inspect(conn.body_params)

      # params =
      # paPoison.decode!(raw_body)
      # pa|> IO.inspect

    case Gateway.DB.API.create(%{}) do
      {:ok, api} ->
        :ok
        # reply with api (see Apiary)
      {:error, changeset} ->
        :error
        # reply with error
    end

    send_resp(conn, 200, "Creating a new API.")
  end
end
