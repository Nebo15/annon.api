defmodule Annon.Plugins.Auth.Strategy do
  @moduledoc """
  Behaviour module for Auth strategies.
  """

  @type token_type :: :bearer

  @doc """
  Fetch consumer data.

  In case error is returned, it's message will be sent to API consumer.
  """
  @callback fetch_consumer(token_type :: token_type,
                           token :: String.t,
                           settings :: Map.t) :: {:ok, Annon.PublicAPI.Consumer.t} | {:error, String.t}
end
