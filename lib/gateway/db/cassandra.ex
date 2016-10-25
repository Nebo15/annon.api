defmodule Gateway.DB.Cassandra do
  @moduledoc """
  Cassandra DB module
  """
#  use Cassandra
  require Logger

  def start_link, do: Cassandra.Connection.start_link(conf())

  def send(frame) do
    Cassandra.Connection.send(Cassandra, CQL.encode(frame))
  end

  def query(string) do
    __MODULE__.send(%CQL.Query{query: string})
  end

  def prepare(string) do
    __MODULE__.send(%CQL.Prepare{query: string})
  end

  def execute(prepared, query, values) do
    __MODULE__.send(%CQL.Execute{
      prepared: prepared,
      params: %CQL.QueryParams{values: values},
    })
#    |> IO.inspect

    %{query: query, prepared: prepared, params: %CQL.QueryParams{values: values},}
#    |> IO.inspect
  end

  def conf do
    Confex.get_map(:gateway, __MODULE__)
  end
end
