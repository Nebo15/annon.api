defmodule Annon.ManagementAPI.Controllers.Dictionaries do
  @moduledoc """
  REST interface that allows to fetch dictionary data.
  """
  use Annon.ManagementAPI.ControllersRouter

  get "/plugins" do
    :annon_api
    |> Application.get_env(:plugins)
    |> Enum.map(fn {name, opts} ->
      module = Keyword.fetch!(opts, :module)
      system? = Keyword.get(opts, :system?, false)
      validation_schema = if system?, do: %{}, else: Poison.encode!(module.settings_validation_schema())

      %{
        name: name,
        validation_schema: validation_schema,
        deps: Keyword.get(opts, :deps, []),
        is_system: system?
      }
    end)
    |> render_collection(conn)
  end
end
