defmodule Gateway.Plugins.APILoader do

  @moduledoc """
  Plugin which get all configuration by endpoint
  """

  import Plug.Conn
  import Ecto.Query, only: [from: 2]

  def init(opts), do: opts

  def call(conn, _), do: put_private(conn, :api_config, conn |> get_config)

  # TODO: Get data from the cache, not from the DataBase
  def get_config(conn) do
    match_spec = %{
      request: %{
        host: conn.host,
        method: conn.method,
        port: conn.port,
        scheme: normalize_scheme(conn.scheme),
        path: conn.request_path
      }
    }
    |> IO.inspect

    :ets.tab2list(:config)
    |> IO.inspect

    IO.puts "In DB:"
    Gateway.DB.Repo.all(Gateway.DB.Models.API)
    |> IO.inspect


    IO.puts "Result:"
    case :ets.match_object(:config, {:_, match_spec}) do
      [{_, api} | _] -> api
      _ -> nil
    end
    |> IO.inspect
  end

  def normalize_scheme(scheme) when is_atom(scheme) do
    Atom.to_string(scheme)
  end

  def normalize_scheme(scheme), do: scheme

  def equal_path?(%{path: path}, conn), do: conn.request_path == path
end
