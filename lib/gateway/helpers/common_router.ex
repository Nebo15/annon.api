defmodule Gateway.Helpers.CommonRouter do
  @moduledoc """
  Response helper
  """
  defmacro __using__(_) do
    quote do
      use Plug.Router

      plug Plug.Parsers, parsers: [:json],
                         pass:  ["application/json"],
                         json_decoder: Poison

      plug :match
      plug :dispatch

      import Gateway.HTTPHelpers.Response
    end
  end
end
