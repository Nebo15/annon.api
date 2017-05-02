defmodule Annon.Configuration.Plugin do
  @moduledoc """
  The boundary for the Plugin Configurations system.
  """
  import Ecto.{Query, Changeset}, warn: false
  alias Annon.Configuration.Repo
  alias Annon.Configuration.Schemas.Plugin, as: PluginSchema
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias Ecto.Changeset
  alias Ecto.Multi

  @plugins %{
    "jwt": Annon.Plugins.JWT,
    "validator": Annon.Plugins.Validator,
    "acl": Annon.Plugins.ACL,
    "proxy": Annon.Plugins.Proxy,
    "idempotency": Annon.Plugins.Idempotency,
    "ip_restriction": Annon.Plugins.IPRestriction,
    "ua_restriction": Annon.Plugins.UARestriction,
    "scopes": Annon.Plugins.Scopes,
    "cors": Annon.Plugins.CORS,
  }

  @plugin_fields [:name, :settings, :is_enabled]
  @required_plugin_fields [:name, :settings]
  @known_plugins Map.keys(@plugins)

  @doc """
  Returns the list of Plugins by API ID.

  ## Examples

      iex> list_plugins(api_id)
      [%Annon.Configuration.Schemas.Plugin{}, ...]

  """
  def list_plugins(api_id) do
    Repo.all from p in PluginSchema,
      where: p.api_id == ^api_id
  end

  @doc """
  Gets a single Plugin.

  ## Examples

      iex> get_plugin(123, "jwt")
      {:ok, %Annon.Configuration.Schemas.Plugin{}}

      iex> get_plugin(123, "jwt")
      {:error, :not_found}

  """
  def get_plugin(api_id, name) when is_binary(name) do
    plugin =
      api_id
      |> get_plugin_query(name)
      |> Repo.one()

    case plugin do
      nil ->
        {:error, :not_found}
      %PluginSchema{} = plugin ->
        {:ok, plugin}
    end
  end

  defp get_plugin_query(api_id, name) do
    from p in PluginSchema, where: p.api_id == ^api_id and p.name == ^name
  end

  @doc """
  Creates a Plugin.

  ## Examples

      iex> create_plugin(%{field: value})
      {:ok, %Annon.Configuration.Schemas.Plugin{}}

      iex> create_plugin(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_plugin(attrs \\ %{}) do
    %PluginSchema{}
    |> plugin_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Create or Update a Plugin.

  Update requires all fields to be present.
  Old Plugin will be deleted, but `id`, `api_id`, `name` and `inserted_at` values will be persisted in new record.

  ## Examples

      iex> create_or_update_plugin(api, "jwt", %{field: new_value})
      {:ok, %Annon.Configuration.Schemas.Plugin{}}

      iex> create_or_update_plugin(api, "jwt", %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_or_update_plugin(%APISchema{} = api, name, attrs) do
    plugin = build_plugin(api, name, attrs)

    multi =
      Multi.new()
      |> Multi.delete_all(:delete, get_plugin_query(api.id, name))
      |> Multi.insert(:insert, plugin)

    case Repo.transaction(multi) do
      {:ok, %{insert: plugin}} -> {:ok, plugin}
      {:error, :insert, changeset, _} -> {:error, changeset}
    end
  end

  defp build_plugin(api, name, attrs) do
    case get_plugin(api.id, name) do
      {:ok, %PluginSchema{inserted_at: inserted_at, id: id}} ->
        id
        |> build_plugin_by_id()
        |> put_change(:name, name)
        |> put_change(:inserted_at, inserted_at)
        |> put_change(:api, api)
        |> plugin_changeset(attrs)

      {:error, :not_found} ->
        %PluginSchema{}
        |> build_plugin_by_id()
        |> put_change(:api, api)
        |> put_change(:name, name)
        |> plugin_changeset(attrs)
    end
  end

  defp build_plugin_by_id(id) when is_number(id),
    do: %PluginSchema{id: id}
  defp build_plugin_by_id(id) when is_binary(id) do
    {id, ""} = Integer.parse(id)
    build_plugin_by_id(id)
  end

  @doc """
  Deletes a Plugin.

  ## Examples

      iex> delete_plugin(123)
      {:ok, %PluginSchema{}}

      iex> delete_plugin(007)
      {:error, :not_found}

  """
  def delete_plugin(%PluginSchema{} = plugin) do
    case Repo.delete(plugin) do
      {:ok, %PluginSchema{} = plugin} ->
        {:ok, plugin}
      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking Plugin changes.

  ## Examples

      iex> change_plugin(plugin)
      %Ecto.Changeset{source: %Annon.Configuration.Schemas.Plugin{}}

  """
  def change_plugin(%PluginSchema{} = plugin) do
    plugin_changeset(plugin, %{})
  end

  defp plugin_changeset(%PluginSchema{} = plugin, attrs) do
    plugin
    |> cast(attrs, @plugin_fields)
    |> validate_required(@required_plugin_fields)
    |> validate_inclusion(:name, @known_plugins)
    |> assoc_constraint(:api)
    |> unique_constraint(:api_id_name)
    |> validate_settings()
  end

  defp validate_settings(%Changeset{valid?: false} = changeset),
    do: changeset
  defp validate_settings(%Changeset{valid?: true} = changeset) do
    %{params: %{"name" => name}} = changeset
    pligin_impl = Map.fetch!(@plugins, name)
    pligin_impl.validate_settings(changeset)
  end
end
