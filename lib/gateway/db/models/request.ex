defmodule Gateway.DB.Models.Request do
  @moduledoc """
    Request embed entity
  """
  use Gateway.DB, :model

  # A required field for all embedded documents
  @primary_key false
  schema "" do
    field :scheme, :string
    field :host, :string
    field :port, :integer
    field :path, :string
    field :method, :string
  end
end