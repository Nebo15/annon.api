defmodule Gateway.Plugins.Helper do

  defmacro plug_call(cb) do
    quote do
      def call(conn, opt) do

        put_private(conn, :api_config, conn |> get_config)
      end
    end
  end

end
