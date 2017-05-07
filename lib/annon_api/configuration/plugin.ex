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

  @plugin_fields [:name, :settings, :is_enabled]
  @required_plugin_fields @plugin_fields
  @plugins Application.fetch_env!(:annon_api, :plugins)
  @known_plugin_names Enum.reduce(@plugins, [], fn {name, opts}, acc ->
    if Keyword.get(opts, :system?, false), do: acc, else: [Atom.to_string(name)] ++ acc
  end)

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

      iex> create_plugin(api, "proxy", %{field: value})
      {:ok, %Annon.Configuration.Schemas.Plugin{}}

      iex> create_plugin(api, "proxy", %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> create_plugin(api, "proxy", %{field: value, name: "not_a_proxy"})
      {:error, %Ecto.Changeset{}}

  """
  def create_plugin(%APISchema{} = api, attrs) do
    %PluginSchema{api: api}
    |> plugin_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update a Plugin.

  Update requires all fields to be present.
  Old Plugin will be deleted, but `id`, `api_id` and `inserted_at` values will be persisted in new record.

  ## Examples

      iex> update_plugin(%PluginSchema{}, %{field: new_value})
      {:ok, %Annon.Configuration.Schemas.Plugin{}}

      iex> update_plugin(%PluginSchema{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_plugin(%PluginSchema{id: id, inserted_at: inserted_at, api_id: api_id, name: name}, attrs) do
    plugin =
      %PluginSchema{id: id}
      |> plugin_changeset(attrs)
      |> put_change(:inserted_at, inserted_at)
      |> put_change(:api_id, api_id)

    multi =
      Multi.new()
      |> Multi.delete_all(:delete, get_plugin_query(api_id, name))
      |> Multi.insert(:insert, plugin)

    case Repo.transaction(multi) do
      {:ok, %{insert: plugin}} -> {:ok, plugin}
      {:error, :insert, changeset, _} -> {:error, changeset}
    end
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

  defp plugin_changeset(%PluginSchema{} = plugin, attrs) do
    plugin
    |> cast(attrs, @plugin_fields)
    |> validate_required(@required_plugin_fields)
    |> validate_inclusion(:name, @known_plugin_names)
    |> assoc_constraint(:api)
    |> unique_constraint(:name, name: :plugins_api_id_name_index, message: "has already been taken")
    |> validate_settings()
  end

  defp validate_settings(%Changeset{valid?: false} = changeset),
    do: changeset
  defp validate_settings(%Changeset{valid?: true} = changeset) do
    %{params: %{"name" => name}} = changeset

    plugin_module =
      @plugins
      |> Keyword.fetch!(String.to_atom(name))
      |> Keyword.fetch!(:module)

    plugin_module.validate_settings(changeset)
  end
end
