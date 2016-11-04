defmodule Gateway.Helpers.CommonRouter do
  @moduledoc """
  Gateway Helpers Common Router
  """
  defmacro __using__(_) do
    quote do
      use Plug.Router
      use Plug.ErrorHandler
      import Gateway.Helpers.Response

      plug :match

      plug Plug.RequestId
      plug Plug.Parsers, parsers: [:json],
                         pass:  ["application/json"],
                         json_decoder: Poison

      plug :dispatch

      def handle_errors(conn, error) do
        Gateway.Helpers.Response.send_internal_error(conn, error)
      end
    end
  end
end
