defmodule Annon.Plugins.Scopes.OAuth2Strategy do
  @moduledoc false

  def get_scopes(nil, _), do: []
  def get_scopes(scope, url_template) do
    scope
    |> get_url(url_template)
    |> retrieve_scopes()
  end

  defp get_url(token, url_template), do: String.replace(url_template, "{token}", token)

  defp retrieve_scopes(url) do
    url
    |> HTTPoison.get!
    |> Map.get(:body)
    |> Poison.decode!
  end
end
