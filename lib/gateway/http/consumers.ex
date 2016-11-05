defmodule Gateway.HTTP.Consumers do
  @moduledoc """
  REST for Consumers
  Documentation http://docs.osapigateway.apiary.io/#reference/consumers
  """
  use Gateway.Helpers.CommonRouter
  alias Gateway.DB.Configs.Repo
  alias Gateway.DB.Schemas.Consumer, as: ConsumerSchema

  get "/" do
    ConsumerSchema
    |> Repo.all
    |> render_collection(conn)
  end

  get "/:consumer_id" do
    ConsumerSchema
    |> Repo.get(consumer_id)
    |> render_schema(conn)
  end

  put "/:consumer_id" do
    consumer_id
    |> ConsumerSchema.update(conn.body_params)
    |> render_change(conn)
  end

  post "/" do
    conn.body_params
    |> ConsumerSchema.create
    |> render_change(conn, 201)
  end

  delete "/:consumer_id" do
    consumer_id
    |> ConsumerSchema.delete
    |> render_delete(conn)
  end

  forward "/", to: Gateway.HTTP.ConsumerPluginSettings
end
