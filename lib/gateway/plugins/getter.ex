defmodule Gateway.Plugins.Getter do

  @moduledoc """
  Plugin which get all configuration by endpoint
  """

  import Plug.Conn
  import Ecto.Query

  def init(opts), do: opts

  def call(conn, _), do: put_private(conn, :api_config, conn |> get_config)

  # TODO: Get data from the cache, not from the DataBase
  def get_config(conn) do
    models = Gateway.DB.Repo.all from Gateway.DB.Models.API,
             preload: [:plugins]

    [config] = models
    |> Enum.filter(fn(x) -> correct?(x, conn) end)

    config
    |> Map.delete(:__meta__)
    |> Map.delete(:__struct__)

  end

  def correct?(%Gateway.DB.Models.API{request: %{} = r}, c) do
    correct_host?(r, c) and correct_port?(r, c) and correct_scheme?(r, c) and correct_path?(r, c)
  end

  def correct_host?(%{host: host}, conn), do: conn.host == host
  def correct_port?(%{port: port}, conn), do: conn.port == port
  def correct_scheme?(%{scheme: scheme}, conn), do: conn.scheme == scheme
  def correct_path?(%{path: path}, conn), do: conn.request_path == path
end
