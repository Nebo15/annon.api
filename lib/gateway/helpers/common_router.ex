defmodule Gateway.Helpers.CommonRouter do
  @moduledoc """
  Gateway Helpers Common Router
  """
  defmacro __using__(_) do
    quote do
      use Plug.Router
      use Plug.ErrorHandler
      import Gateway.HTTPHelpers.Response

      plug :match

      plug Plug.Parsers, parsers: [:json],
                         pass:  ["application/json"],
                         json_decoder: Poison

      plug :dispatch

      def handle_errors(conn, error) do
        Gateway.Helpers.HTTP.Errors.send_internal_error(conn, error)
      end
    end
  end
end
