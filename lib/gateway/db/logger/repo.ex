defmodule Annon.DB.Logger.Repo do
  @moduledoc """
  This repo is used to store request and responses.

  We recommend database with low write latency,
  because it will have up to 2 writes for each API call that is going trough Annon.

  Also, if Idempotency plug is enabled and `X-Idempotency-Key: <key>` header is sent by a consumer,
  you can expect an additional read request.
  """

  use Ecto.Repo, otp_app: :gateway
  use Ecto.Pagging.Repo
end
