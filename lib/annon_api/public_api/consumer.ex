defmodule Annon.PublicAPI.Consumer do
  @moduledoc """
  This module defines struct to carry API consumer,
  """

  @type scope :: String.t | [String.t]
  @type t :: %{id: String.t, scope: scope, metadata: Map.t}

  defstruct id: nil,
            scope: "",
            metadata: %{}
end
