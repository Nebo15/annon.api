defmodule Gateway.Helpers.Scopes.JWTStrategy do
  @moduledoc """
  Helper for retrieving scopes with JWT strategy - getting scopes from token.
  """

  alias Joken.Token

  defp extract_token_scopes(%Token{claims: token_claims}),
    do: extract_token_scopes(token_claims)
  defp extract_token_scopes(%{"scopes" => scopes}),
    do: scopes
  defp extract_token_scopes(%{"app_metadata" => %{"scopes" => scopes}}) when is_list(scopes),
    do: scopes
  defp extract_token_scopes(%{"app_metadata" => %{"scopes" => scopes}}) when is_binary(scopes),
    do: String.split(scopes, ",")
  defp extract_token_scopes(_),
    do: nil

  def get_scopes(token) do
    token
    |> extract_token_scopes
  end
end
