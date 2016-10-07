defmodule Gateway.HTTP.API do
  @moduledoc """
  REST for api
  Documentation http://docs.osapigateway.apiary.io/#reference/apis
  """
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Getting a new API.")
  end

  post "/" do
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
