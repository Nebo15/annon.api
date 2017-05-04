defmodule Annon.Configuration.API do
  @moduledoc """
  The boundary for the API Configurations system.
  """
  import Ecto.{Query, Changeset}, warn: false
  alias Annon.Configuration.Repo
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias Ecto.Multi
  alias Ecto.Paging

  # @api_fields [:name, :description, :health, :docs_url, :disclose_status]
  @required_api_fields [:name]
  @required_api_request_fields [:scheme, :host, :port, :path, :methods]
  @known_http_verbs ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"]

  @doc """
  Returns the list of APIs.

  Response can be filtered by title if there is a `"title"` filed in `conditions`.

  ## Examples

      iex> list_apis()
      {[%Annon.Configuration.Schemas.API{}, ...], %Ecto.Paging{}}

  """
  def list_apis(conditions \\ %{}, %Paging{} = paging \\ %Paging{limit: 50}) do
    APISchema
    |> maybe_filter_name(conditions)
    |> Repo.page(paging)
  end

  defp maybe_filter_name(query, %{"name" => name}) when is_binary(name) do
    name_ilike = "%" <> name <> "%"
    where(query, [a], ilike(a.name, ^name_ilike))
  end
  defp maybe_filter_name(query, _),
    do: query

  @doc """
  Gets a single API.

  ## Examples

      iex> get_api(123)
      {:ok, %Annon.Configuration.Schemas.API{}}

      iex> get_api(456)
      {:error, :not_found}

  """
  def get_api(id) do
    case Repo.get(APISchema, id) do
      nil -> {:error, :not_found}
      api -> {:ok, api}
    end
  end

  @doc """
  Creates a API.

  ## Examples

      iex> create_api(%{field: value})
      {:ok, %Annon.Configuration.Schemas.API{}}

      iex> create_api(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_api(attrs) do
    %APISchema{}
    |> api_changeset(attrs)
    |> Repo.insert()
  end
  def create_api(id, attrs) do
    %APISchema{id: id}
    |> api_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update a API.

  Update requires all fields to be present.
  Old API will be deleted, but `id` and `inserted_at` values will be persisted in new record.

  ## Examples

      iex> update_api(api, %{field: new_value})
      {:ok, %Annon.Configuration.Schemas.API{}}

      iex> update_api(api, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_api(%APISchema{id: id, inserted_at: inserted_at}, attrs) do
    api =
      id
      |> build_api_by_id()
      |> api_changeset(attrs)
      |> put_change(:inserted_at, inserted_at)

    multi =
      Multi.new()
      |> Multi.delete_all(:delete, from(a in APISchema, where: a.id == ^id))
      |> Multi.insert(:insert, api)

    case Repo.transaction(multi) do
      {:ok, %{insert: api}} -> {:ok, api}
      {:error, :insert, changeset, _} -> {:error, changeset}
    end
  end

  defp build_api_by_id(id) when is_binary(id),
    do: %APISchema{id: id}

  @doc """
  Deletes a API.

  ## Examples

      iex> delete_api(123)
      {:ok, %API{}}

      iex> delete_api(007)
      {:error, :not_found}

  """
  def delete_api(%APISchema{} = api) do
    case Repo.delete(api) do
      {:ok, %APISchema{} = api} ->
        {:ok, api}
      {:error, _} ->
        {:error, :not_found}
    end
  end

  defp api_changeset(%APISchema{} = api, attrs) do
    api
    |> cast(attrs, @required_api_fields)
    |> validate_required(@required_api_fields)
    |> unique_constraint(:name, name: :apis_name_index)
    |> unique_constraint(:request, name: :api_unique_request_index)
    |> cast_embed(:request, with: &request_changeset/2)
  end

  def request_changeset(%APISchema.Request{} = request, attrs) do
    management_api_port =
      :annon_api
      |> Confex.get_map(:management_http)
      |> Keyword.fetch!(:port)

    request
    |> cast(attrs, @required_api_request_fields)
    |> validate_required(@required_api_request_fields)
    |> validate_subset(:methods, @known_http_verbs)
    |> validate_exclusion(:port, [management_api_port], message: "This port is reserver for Management API")
  end
end
