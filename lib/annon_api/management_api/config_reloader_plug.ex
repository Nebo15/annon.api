defmodule Annon.ManagementAPI.ConfigReloaderPlug do
  @moduledoc """
  This plugin
  [invalidates Annons cache](http://docs.annon.apiary.io/#introduction/general-features/caching-and-perfomance)
  whenever there was change done by a Management API.
  """
  @destructive_methods ["POST", "PUT", "DELETE"]
  @successful_statuses [200, 201, 204]

  def init([subscriber: _] = opts),
    do: opts

  def call(%Plug.Conn{method: method, status: status} = conn, [subscriber: subscriber])
      when method in @destructive_methods and status in @successful_statuses do
    subscriber.()

    conn
  end
  def call(conn, _opts),
    do: conn
end
