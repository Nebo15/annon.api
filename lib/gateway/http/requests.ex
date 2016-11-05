defmodule Gateway.HTTP.Requests do
  @moduledoc """
  REST for Requests
  Documentation http://docs.osapigateway.apiary.io/#reference/requests
  """
  use Gateway.Helpers.CommonRouter
  alias Gateway.DB.Logger.Repo
  alias Gateway.DB.Schemas.Log, as: LogSchema

  get "/" do
    LogSchema
    |> Repo.all
    |> render_collection(conn)
  end

  get "/:request_id" do
    [id: request_id]
    |> LogSchema.get_one_by()
    |> render_schema(conn)
  end

  delete "/:request_id" do
    request_id
    |> LogSchema.delete()
    |> render_delete(conn)
  end
end
