defmodule Gateway.Helpers.CommonRouter do
  @moduledoc """
  This router is used in controllers of Annons private API.
  """
  defmacro __using__(_) do
    quote location: :keep do
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
