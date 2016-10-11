defmodule Gateway.Monitoring do
    import Plug.Conn

    def init(opts) do
        opts
    end

    def call(conn, opts) do
        IO.inspect Plug.Con..read_body(conn)
    end    
end