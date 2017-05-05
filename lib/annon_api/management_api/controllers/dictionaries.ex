defmodule Annon.ManagementAPI.Controllers.Dictionaries do
  @moduledoc """
  REST interface that allows to fetch dictionary data.
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
