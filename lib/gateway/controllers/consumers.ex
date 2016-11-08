defmodule Gateway.Controllers.Consumers do
  @moduledoc """
  REST interface that allows to manage Consumers and their settings overrides.

  Consumer is a authorization entity that can be accessed any unique external it.
  It stores scopes and metadata. Scopes can be used by authorization plugins.

  By overriding plugin settings for a consumer you can define personal rules for processing hes requests.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/consumers).
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

  forward "/", to: Gateway.Controllers.Consumers.PluginSettings
end
