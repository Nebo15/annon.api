defmodule Gateway.HTTP.Consumers do
  @moduledoc """
  REST for Consumers
  Documentation http://docs.osapigateway.apiary.io/#reference/consumers
  """
  use Gateway.Helpers.CommonRouter

  get "/" do
    Gateway.DB.Models.Consumer
    |> Gateway.DB.Repo.all
    |> render_response(conn)
  end

  get "/:consumer_id" do
    Gateway.DB.Models.Consumer
    |> Gateway.DB.Repo.get(consumer_id)
    |> render_response(conn)
  end

  put "/:consumer_id" do
    consumer_id
    |> Gateway.DB.Models.Consumer.update(conn.body_params)
    |> render_response(conn)
  end

  post "/" do
    conn.body_params
    |> Gateway.DB.Models.Consumer.create
    |> render_response(conn, 201)
  end

  delete "/:consumer_id" do
    consumer_id
    |> Gateway.DB.Models.Consumer.delete
    |> render_delete_response(conn)
  end

  forward "/", to: Gateway.HTTP.ConsumerPluginSettings
end
