defmodule Annon.Configuration.CacheAdapter do
  @moduledoc """
  Adapter for API Gateway configuration loaders.
  """

  @doc """
  Initializes configuration adapter.
  """
  @callback init() :: :ok

  @doc """
  Returns oldest API and associated Plugins that matches request parameters.
  """
  @callback match_request(scheme :: String.t,
                          method :: String.t,
                          host :: String.t,
                          port :: number,
                          path :: String.t) :: {:ok, Map.t} | {:error, :not_found}

  @doc """
  Updates cache information when configuration is changed.
  """
  @callback config_change() :: :ok
end
