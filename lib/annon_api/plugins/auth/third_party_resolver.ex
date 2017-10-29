defmodule Annon.Plugins.Auth.ThirdPartyResolver do
  @moduledoc """
  Behaviour module for Auth strategies.
  """
  require Logger
  alias Annon.PublicAPI.Consumer
  alias HTTPoison.Response

  def call_third_party_resolver(url, api_key \\ nil) do
    headers = [{"content-type", "application/json"}, {"accept", "application/json"}, {"api-key", api_key}]

    with {:ok, %Response{status_code: 200, body: body}}
            when is_binary(body) and body != "" <- HTTPoison.get(url, headers),
         {:ok, response} <- Poison.decode(body) do
      parse_success_response(response)
    else
      {:ok, %Response{status_code: 401, body: error_body}} ->
        {:error, get_error_message(error_body, :invalid_status_code)}

      {:ok, %Response{status_code: status_code, body: body}} ->
        Logger.error(fn ->
          "Auth - Third party resolver: HTTP GET to #{url} received HTTP #{to_string(status_code)} code " <>
          "with body #{inspect body}."
        end)
        {:error, :invalid_response}

      {:error, reason} ->
        Logger.error(fn ->
          "Auth - Third party resolver: can not decode third party response, reason: #{inspect reason}."
        end)
        {:error, :unavailable}
    end
  end

  defp parse_success_response(%{"user_id" => consumer_id, "details" => %{"scope" => consumer_scope} = metadata}),
    do: {:ok, %Consumer{id: consumer_id, scope: consumer_scope, metadata: metadata}}
  defp parse_success_response(%{"consumer_id" => consumer_id, "consumer_scope" => consumer_scope}),
    do: {:ok, %Consumer{id: consumer_id, scope: consumer_scope}}
  defp parse_success_response(%{"data" => data}),
    do: parse_success_response(data)
  defp parse_success_response(response) do
    Logger.error(fn ->
      "Auth - Can not process third party response: #{inspect response}."
    end)
    {:error, :invalid_response}
  end

  defp get_error_message(body, default) do
    case Poison.decode(body) do
      {:ok, %{"error" => %{"message" => message}}} ->
        message
      _ ->
        default
    end
  end
end
