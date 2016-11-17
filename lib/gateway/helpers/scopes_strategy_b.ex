defmodule Gateway.Helpers.Scopes.StrategyB do
  @moduledoc """
  Helper for retrieving scopes with strategy B - getting scopes from PCM by party_id.
  """

  defp get_url(party_id, url_template), do: String.replace(url_template, "{party_id}", party_id)

  defp retrieve_scopes(nil), do: []
  defp retrieve_scopes(url) do
    url
    |> HTTPoison.get!
    |> Map.get(:body)
    |> Poison.decode!
    |> get_in(["data", "scopes"])
  end

  def get_scopes(party_id, url_template) do
    party_id
    |> get_url(url_template)
    |> retrieve_scopes()
  end
end
