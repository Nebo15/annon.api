defmodule Gateway.Helpers.CommonRouter do
  @moduledoc """
  Gateway Helpers Common Router
  """
  defmacro __using__(_) do
    quote do
      use Plug.Router

      plug :match

      plug Plug.Parsers, parsers: [:json],
                         pass:  ["application/json"],
                         json_decoder: Poison

      plug :dispatch

      import Gateway.HTTPHelpers.Response
    end
  end
end
