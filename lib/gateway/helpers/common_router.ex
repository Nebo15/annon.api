defmodule Gateway.Helpers.CommonRouter do
  @moduledoc """
  Gateway Helpers Common Router
  """
  defmacro __using__(_) do
    quote do
      use Plug.Router
      import Gateway.Helpers.Response
      import Gateway.Helpers.Render

      plug :match

      plug Plug.RequestId
      plug Plug.Parsers, parsers: [:json],
                         pass:  ["application/json"],
                         json_decoder: Poison

      plug :dispatch
    end
  end
end
