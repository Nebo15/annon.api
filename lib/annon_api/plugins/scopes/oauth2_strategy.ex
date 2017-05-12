defmodule Annon.Plugins.Scopes.OAuth2Strategy do
  @moduledoc false

  def token_attributes(nil, _), do: nil
  def token_attributes(scope, url_template) do
    scope
    |> get_url(url_template)
    |> retrieve_token_attributes()
  end

  defp get_url(token, url_template), do: String.replace(url_template, "{token}", token)

  defp retrieve_token_attributes(url) do
    response = HTTPoison.get!(url)

    if response.status_code == 200 do
      Poison.decode!(response.body)
    end
  end
end
