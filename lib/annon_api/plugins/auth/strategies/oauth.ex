defmodule Annon.Plugins.Auth.Strategies.OAuth do
  @moduledoc """
  JWT adapter for Auth strategies.
  """
  alias Annon.PublicAPI.Consumer
  alias Annon.Plugins.Auth.ThirdPartyResolver
  @behaviour Annon.Plugins.Auth.Strategy

  def fetch_consumer(:bearer, token, settings, api_key \\ nil) do
    %{"url_template" => url_template} = settings

    resp =
      url_template
      |> String.replace("{access_token}", token)
      |> ThirdPartyResolver.call_third_party_resolver(api_key)

    case resp do
      {:ok, %Consumer{} = consumer} ->
        {:ok, consumer}
      {:error, message} when is_binary(message) ->
        {:error, message}
      {:error, reason} when is_atom(reason) ->
        {:error, "Invalid access token"}
    end
  end
end
