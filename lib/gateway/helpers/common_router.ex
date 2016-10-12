defmodule Gateway.Helpers.CommonRouter do
  defmacro __using__(_) do
    quote do
      use Plug.Router

      plug Plug.Parsers, parsers: [:json],
                         pass:  ["application/json"],
                         json_decoder: Poison

      plug :match
      plug :dispatch

#      import Gateway.Helpers.CommonRouter
      import Gateway.HTTPHelpers.Response
    end
  end

#  def send_response({code, resp}, conn) do
#    send_resp(conn, code, resp)
#  end
end
