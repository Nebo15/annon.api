defmodule Gateway.Plugins.ApiLoader do

  @moduledoc """
  Plugin which get all configuration by endpoint
  """

  import Plug.Conn
  import Ecto.Query, only: [from: 2]

  def init(opts), do: opts

  def call(conn, _), do: put_private(conn, :api_config, conn |> get_config)

  # TODO: Get data from the cache, not from the DataBase
  # ToDo: use join for preload'
  def get_config(conn) do
    models = Gateway.DB.Repo.all from Gateway.DB.Models.API,
             preload: [:plugins]

    models
    |> Enum.filter(fn(x) -> equal?(x, conn) end)
    |> get_one

  end

  def get_one([model]), do: model
  def get_one(_), do: nil

  def equal?(%{request: %{} = r}, c) do
    equal_host?(r, c) and equal_port?(r, c) and equal_scheme?(r, c) and equal_path?(r, c) and equal_method?(r, c)
  end

  def equal_host?(%{host: host}, conn), do: conn.host == host
  def equal_method?(%{method: method}, conn), do: conn.method == method
  def equal_port?(%{port: port}, conn), do: conn.port == port
  def equal_scheme?(%{scheme: scheme}, %Plug.Conn{scheme: conn_scheme}) when is_atom(conn_scheme) do
    conn_scheme
    |> Atom.to_string
    |> equal_scheme?(scheme)
  end
  def equal_scheme?(%{scheme: scheme}, %Plug.Conn{scheme: conn_scheme}) when is_binary(conn_scheme) do
    equal_scheme?(conn_scheme, scheme)
  end
  def equal_scheme?(conn_scheme, scheme) when is_binary(scheme) and is_binary(conn_scheme), do: scheme == conn_scheme

  def equal_path?(%{path: path}, conn), do: conn.request_path == path
end
