defmodule Annon.ManagementAPI.ControllersRouter do
  @moduledoc """
  This router is used in controllers of Annons management API.
  """
  defmacro __using__(_) do
    quote location: :keep do
      use Plug.Router
      import Annon.Helpers.Response
      import Annon.ManagementAPI.Render

      plug :match
      plug :dispatch
    end
  end
end
