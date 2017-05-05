defmodule Annon.ManagementAPI.Controllers.Dictionaries do
  @moduledoc """
  REST interface that allows to fetch and delete stored requests.

  By-default, Annon will store all request and response structure in a persistent storage,
  and it's completely up to you how do you manage data retention in it.

  This data is used by Idempotency plug and by dashboard that shows near-realtime metrics on Annons perfomance.

  You can find full description in [REST API documentation](http://docs.annon.apiary.io/#reference/requests).
  """
  use Annon.ManagementAPI.ControllersRouter

  get "/plugins" do
    :annon_api
    |> Application.get_env(:plugins)
    |> Enum.map(fn {name, module} ->
      %{
        name: name,
        validation_schema: Poison.encode!(module.settings_validation_schema())
      }
    end)
    |> render_collection(conn)
  end
end
