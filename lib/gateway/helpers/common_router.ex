defmodule Gateway.Helpers.CommonRouter do
  @moduledoc """
  Gateway Helpers Common Router
  """
  defmacro __using__(_) do
    quote do
      use Plug.Router
      use Plug.ErrorHandler
      import Gateway.Helpers.Response
      import Gateway.Helpers.Render

      plug :match

      plug Plug.RequestId
      plug Plug.Parsers, parsers: [:json],
                         pass:  ["application/json"],
                         json_decoder: Poison

      plug :dispatch

      def handle_errors(conn, error) do
        conn
        |> send_error(error)
      end
    end
  end
end
