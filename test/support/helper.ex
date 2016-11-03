defmodule Gateway.Test.Helper do
  @moduledoc """
  This module provides helper functions to be used in tests
  """

  def random_string(length) do
    data = :crypto.strong_rand_bytes(length)
    data |> Base.url_encode64 |> binary_part(0, length)
  end

  def remove_type(resp_body) do
    data = resp_body
    |> Poison.decode!()
    |> Map.get("data")
    |> Map.delete("type")

    resp_body
    |> Poison.decode!()
    |> Map.put("data", data)
    |> Poison.encode!()
  end

end
