defmodule Gateway.Helpers.IP do
  @moduledoc """
  Helper for working with IP
  """

  def ip_to_string(ip) do
    ip
    |> Tuple.to_list
    |> Enum.join(".")
  end
end
