defmodule Gateway.Workers.Cassandra do
  @moduledoc """
  Cassandra worker
  """
#  alias Gateway.DB.CassandraAPI
#  import Gateway.Helpers.Cassandra

  def send(frame) do
    Cassandra.Connection.send(Cassandra, CQL.encode(frame))
  end

  def query(string) do
    __MODULE__.send(%CQL.Query{query: string})
  end

  def prepare(string) do
    __MODULE__.send(%CQL.Prepare{query: string})
  end

  def execute(prepared, values) do
    __MODULE__.send(%CQL.Execute{
      prepared: prepared,
      params: %CQL.QueryParams{values: values},
    })
  end
end
