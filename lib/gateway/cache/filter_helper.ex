defmodule Gateway.Cache.FilterHelper do
  @moduledoc """
  Helper for filtering responses from adapters
  """

  def do_filter(response, host) do
    response
    |> Enum.map_reduce([], fn(api, acc) -> {api, put_in_acc(acc, api, host)} end)
    |> make_response()
  end

  def put_in_acc(acc, %Gateway.DB.Schemas.API{request: %Gateway.DB.Schemas.API.Request{host: host}} = api, needed_host)
      when host == needed_host do
    Kernel.++(acc, [api])
  end
  def put_in_acc(acc, _api, _needed_host), do: acc

  def make_response({_list, filtered}) when length(filtered) > 0, do: filtered
  def make_response({list, _filtered}), do: list
end
