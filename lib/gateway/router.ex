defmodule Gateway.Router do
  @moduledoc """
  Gateway HTTP Router
  """
  use Plug.Router
<<<<<<< 18a5156aad41506fe955663fd5698b0271a7b2d0
=======
  
  plug Gateway.Monitoring
  plug Plug.Parsers, parsers: [:json],
                     pass:  ["application/json"],
                     json_decoder: Poison
>>>>>>> initial commit

  plug :match
  plug :dispatch

  forward "/apis", to: Gateway.HTTP.API
end
