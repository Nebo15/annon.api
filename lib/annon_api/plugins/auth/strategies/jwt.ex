defmodule Annon.Plugins.Auth.Strategies.JWT do
  @moduledoc """
  JWT adapter for Auth strategies.
  """
  import Joken
  alias Joken.Token
  alias Annon.PublicAPI.Consumer
  alias Annon.Plugins.Auth.ThirdPartyResolver
  @behaviour Annon.Plugins.Auth.Strategy

  def fetch_consumer(:bearer, token, settings) do
    %{"secret" => secret, "algorithm" => algorithm} = settings

    signer =
      secret
      |> Base.decode64!()
      |> get_signer(algorithm)

    jwt_token =
      token
      |> token()
      |> with_signer(signer)

    with %Token{error: nil} = jwt_token <- verify(jwt_token),
         %Consumer{} = consumer <- get_consumer(jwt_token),
         %Consumer{} = consumer <- put_scope(consumer, settings) do
      {:ok, consumer}
    else
      %Token{error: _message} -> {:error, "JWT token is invalid"}
      {:error, :consumer_id_is_not_set} -> {:error, "JWT token does not contain Consumer ID"}
      {:error, :third_party_resolver} -> {:error, "JWT token can not be authorized"}
    end
  end

  # defp get_signer(decoded_secret, "ES256"),
  #   do: es256(decoded_secret)
  # defp get_signer(decoded_secret, "ES384"),
  #   do: es384(decoded_secret)
  # defp get_signer(decoded_secret, "ES512"),
  #   do: es512(decoded_secret)
  defp get_signer(decoded_secret, "HS256"),
    do: hs256(decoded_secret)
  defp get_signer(decoded_secret, "HS384"),
    do: hs384(decoded_secret)
  defp get_signer(decoded_secret, "HS512"),
    do: hs512(decoded_secret)
  # defp get_signer(decoded_secret, "PS256"),
  #   do: ps256(decoded_secret)
  # defp get_signer(decoded_secret, "PS384"),
  #   do: ps384(decoded_secret)
  # defp get_signer(decoded_secret, "PS512"),
  #   do: ps512(decoded_secret)
  # defp get_signer(decoded_secret, "RS256"),
  #   do: rs256(decoded_secret)
  # defp get_signer(decoded_secret, "RS384"),
  #   do: rs384(decoded_secret)
  # defp get_signer(decoded_secret, "RS512"),
  #   do: rs512(decoded_secret)
  # defp get_signer(decoded_secret, "Ed25519"),
  #   do: ed25519(decoded_secret)
  # defp get_signer(decoded_secret, "Ed25519ph"),
  #   do: ed25519ph(decoded_secret)
  # defp get_signer(decoded_secret, "Ed448ph"),
  #   do: ed448ph(decoded_secret)
  # defp get_signer(decoded_secret, "Ed448"),
  #   do: ed448(decoded_secret)

  defp get_consumer(%Token{claims: claims}) do
    case get_consumer_id(claims) do
      nil ->
        {:error, :consumer_id_is_not_set}
      consumer_id ->
        %Consumer{
          id: consumer_id,
          metadata: claims
        }
    end
  end

  defp get_consumer_id(%{"consumer_id" => consumer_id}) when is_number(consumer_id),
    do: to_string(consumer_id)
  defp get_consumer_id(%{"consumer_id" => consumer_id}) when is_binary(consumer_id),
    do: consumer_id
  # This adds support for Auth0 `app_metadata`
  defp get_consumer_id(%{"app_metadata" => metadata}),
    do: get_consumer_id(metadata)
  defp get_consumer_id(_),
    do: nil

  defp put_scope(%{metadata: metadata} = consumer, %{"third_party_resolver" => false}),
    do: Map.put(consumer, :scope, get_consumer_scope(metadata))
  defp put_scope(%Consumer{} = consumer, %{"third_party_resolver" => true, "url_template" => url_template}) do
    %{id: consumer_id} = consumer

    resp =
      url_template
      |> String.replace("{consumer_id}", consumer_id)
      |> ThirdPartyResolver.call_third_party_resolver()

    case resp do
      {:ok, %Consumer{scope: scope}} ->
        Map.put(consumer, :scope, scope)
      {:error, _reason} ->
        {:error, :third_party_resolver}
    end
  end

  defp get_consumer_scope(%{"consumer_scope" => consumer_scope}) when is_list(consumer_scope),
    do: Enum.join(consumer_scope, " ")
  defp get_consumer_scope(%{"consumer_scope" => consumer_scope}),
    do: consumer_scope
  # This adds support for Auth0 `app_metadata`
  defp get_consumer_scope(%{"app_metadata" => metadata}),
    do: get_consumer_scope(metadata)
  defp get_consumer_scope(_),
    do: ""
end
