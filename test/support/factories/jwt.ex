defmodule Annon.Factories.JWT do
  @moduledoc false
  def jwt_token_factory(payload, signature, algorithm \\ :hs256) do
    signature = apply(Joken, algorithm, [Base.decode64!(signature)])

    payload
    |> Joken.token()
    |> Joken.sign(signature)
    |> Joken.get_compact()
  end
end
