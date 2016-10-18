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
    |> Enum.filter(fn(x) -> correct?(x, conn) end)
    |> get_one

  end

  def get_one([model]), do: model
  def get_one(_), do: nil

  def correct?(%{request: %{} = r}, c) do
    correct_host?(r, c) and correct_port?(r, c) and correct_scheme?(r, c) and correct_path?(r, c)
  end

  def correct_host?(%{host: host}, conn), do: conn.host == host
  def correct_port?(%{port: port}, conn), do: conn.port == port
  def correct_scheme?(%{scheme: scheme}, %{scheme: conn_scheme}) when is_atom(conn_scheme) do
    Atom.to_string(conn_scheme) == scheme
  end
  def correct_scheme?(%{scheme: scheme}, conn), do: conn.scheme == scheme
  def correct_path?(%{path: path}, conn), do: conn.request_path == path
end
