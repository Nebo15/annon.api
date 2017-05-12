defmodule Annon.Plugins.Auth.ThirdPartyResolver do
  @moduledoc """
  Behaviour module for Auth strategies.
  """
  require Logger
  alias Annon.PublicAPI.Consumer
  alias HTTPoison.Response

  def call_third_party_resolver(url) do
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}]
    with {:ok, %Response{status_code: 200, body: body}}
            when is_binary(body) and body != "" <- HTTPoison.get(url, headers),
         {:ok, response} <- Poison.decode(body) do
      parse_response(response)
    else
      {:ok, %Response{status_code: status_code}} ->
        Logger.error(fn ->
          "Auth - Third party resolver: HTTP GET to #{url} received HTTP #{to_string(status_code)} code."
        end)
        {:error, "Third party resolver is unavailable"}

      {:error, reason} ->
        Logger.error(fn ->
          "Auth - Third party resolver: can not decode third party response, reason: #{inspect reason}."
        end)
        {:error, "Can not get third party resolver response."}
    end
  end

  defp parse_response(%{"user_id" => consumer_id, "details" => %{"scope" => consumer_scope}}),
    do: {:ok, %Consumer{id: consumer_id, scope: consumer_scope}}
  defp parse_response(%{"consumer_id" => consumer_id, "consumer_scope" => consumer_scope}),
    do: {:ok, %Consumer{id: consumer_id, scope: consumer_scope}}
  defp parse_response(%{"data" => data}),
    do: parse_response(data)
  defp parse_response(response),
    do: {:error, "Can not process third party resolver response, #{inspect response}."}
end
