defmodule Annon.Plugins.Auth.Strategies.OAuth do
  @moduledoc """
  JWT adapter for Auth strategies.
  """
  alias Annon.PublicAPI.Consumer
  alias Annon.Plugins.Auth.ThirdPartyResolver
  @behaviour Annon.Plugins.Auth.Strategy

  def fetch_consumer(:bearer, token, settings) do
    %{"url_template" => url_template} = settings

    resp =
      url_template
      |> String.replace("{access_token}", token)
      |> ThirdPartyResolver.call_third_party_resolver()

    case resp do
      {:ok, %Consumer{} = consumer} ->
        {:ok, consumer}
      {:error, _reason} ->
        {:error, "Invalid access token"}
    end
  end
end
