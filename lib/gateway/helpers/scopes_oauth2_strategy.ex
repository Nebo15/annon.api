defmodule Gateway.Helpers.Scopes.OAuth2Strategy do
  def get_scopes(nil, _), do: []
  def get_scopes(scope, url_template) do
    scope
    |> get_url(url_template)
    |> retrieve_scopes()
    |> prepare_scopes()
  end

  defp get_url(token, url_template), do: String.replace(url_template, "{token}", token)

  defp retrieve_scopes(url) do
    url
    |> HTTPoison.get!
    |> Map.get(:body)
    |> Poison.decode!
    |> get_in(["data", "details", "scope"])
  end

  defp prepare_scopes(nil), do: []
  defp prepare_scopes(string), do: String.split(string, ",")
end
