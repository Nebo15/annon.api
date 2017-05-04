defmodule Annon.Requests.Log do
  @moduledoc """
  The boundary for the Requests Log system.
  """
  import Ecto.{Query, Changeset}, warn: false
  alias Annon.Requests.Repo
  alias Annon.Requests.Request
  alias Ecto.Paging

  @request_fields [:id, :idempotency_key, :ip_address, :status_code]
  @required_request_fields [:response, :status_code]
  @http_request_fields [:method, :uri, :query, :headers, :body]
  @http_response_fields [:status_code, :headers, :body]
  @latencies_fields [:gateway, :upstream, :client_request]
  @api_fields [:id, :name]
  @api_request_fields [:scheme, :host, :port, :path]

  @doc """
  Returns the list of Logs.

  Response can be filtered by title if there is a `"title"` filed in `conditions`.

  ## Examples

      iex> list_requests()
      {[%Annon.Requests.Request{}, ...], %Ecto.Paging{}}

  """
  def list_requests(conditions \\ %{}, %Paging{} = paging \\ %Paging{limit: 50}) do
    Request
    |> maybe_filter_idempotency_key(conditions)
    |> maybe_filter_api_ids(conditions)
    |> maybe_filter_status_codes(conditions)
    |> maybe_filter_ip_addresses(conditions)
    |> order_by(desc: :inserted_at)
    |> Repo.page(paging)
  end

  defp maybe_filter_idempotency_key(query, %{"idempotency_key" => idempotency_key}) when is_binary(idempotency_key) do
    where(query, [r], r.idempotency_key == ^idempotency_key)
  end
  defp maybe_filter_idempotency_key(query, _),
    do: query

  defp maybe_filter_api_ids(query, %{"api_ids" => api_ids}) when is_binary(api_ids) do
    ids =
      api_ids
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    where(query, [r], fragment("?->'id' \\?| ?", r.api, ^ids))
  end
  defp maybe_filter_api_ids(query, _),
    do: query

  defp maybe_filter_status_codes(query, %{"status_codes" => status_codes}) when is_binary(status_codes) do
    codes =
      status_codes
      |> String.split(",")
      |> Enum.filter(fn status_code ->
        case Integer.parse(status_code) do
          {_code, ""} -> true
          _ -> false
        end
      end)

    where(query, [r], r.status_code in ^codes)
  end
  defp maybe_filter_status_codes(query, _),
    do: query

  defp maybe_filter_ip_addresses(query, %{"ip_addresses" => ip_addresses}) when is_binary(ip_addresses) do
    ips = String.split(ip_addresses, ",")
    where(query, [r], r.ip_address in ^ips)
  end
  defp maybe_filter_ip_addresses(query, _),
    do: query

  @doc """
  Gets a single Request.

  ## Examples

      iex> get_request(123)
      {:ok, %Annon.Requests.Request{}}

      iex> get_request(456)
      {:error, :not_found}

  """
  def get_request(id) do
    case Repo.get(Request, id) do
      nil -> {:error, :not_found}
      request -> {:ok, request}
    end
  end

  @doc """
  Gets a single Request by a selector.

  ## Examples

      iex> get_request_by([idempotency_key: "my_key"])
      {:ok, %Annon.Requests.Request{}}

      iex> get_request_by([idempotency_key: "bad_my_key"])
      {:error, :not_found}

  """
  def get_request_by(selector) do
    case Repo.get_by(Request, selector) do
      nil -> {:error, :not_found}
      request -> {:ok, request}
    end
  end

  @doc """
  Creates a Request.

  ## Examples

      iex> create_request(%{field: value})
      {:ok, %Annon.Requests.Request{}}

      iex> create_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_request(attrs \\ %{}) do
    %Request{}
    |> request_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a Request.

  ## Examples

      iex> delete_request(123)
      {:ok, %Request{}}

      iex> delete_request(007)
      {:ok, %Request{}}

  """
  def delete_request(%Request{} = request) do
    case Repo.delete(request) do
      {:ok, %Request{} = request} ->
        {:ok, request}
      {:error, _} ->
        {:error, :not_found}
    end
  end

  # Changesets

  defp request_changeset(%Request{} = request, attrs) do
    request
    |> cast(attrs, @request_fields)
    |> cast_embed(:api, with: &api_changeset/2)
    |> cast_embed(:request, with: &http_request_changeset/2)
    |> cast_embed(:response, with: &http_response_changeset/2)
    |> cast_embed(:latencies, with: &latencies_changeset/2)
    |> validate_required(@required_request_fields)
  end

  defp http_request_changeset(%Request.HTTPRequest{} = http_request, attrs) do
    http_request
    |> cast(attrs, @http_request_fields)
  end

  defp http_response_changeset(%Request.HTTPResponse{} = http_response, attrs) do
    http_response
    |> cast(attrs, @http_response_fields)
  end

  defp latencies_changeset(%Request.Latencies{} = latencies, attrs) do
    latencies
    |> cast(attrs, @latencies_fields)
  end

  defp api_changeset(%Request.API{} = api, attrs) do
    api
    |> cast(attrs, @api_fields)
    |> cast_embed(:request, with: &api_request_changeset/2)
  end

  defp api_request_changeset(%{} = api_request, attrs) do
    api_request
    |> cast(attrs, @api_request_fields)
  end
end
