defmodule Annon.ManagementAPI.Controllers.Monitoring do
  @moduledoc """
  This controller provides action functions for monitoring endpoints.
  """
  alias Annon.ManagementAPI.Render
  alias Annon.Helpers.Response
  alias Annon.Monitoring.ClusterStatus
  alias Annon.Configuration.API
  alias Annon.Requests.Analytics
  alias Ecto.Changeset

  def list_cluster_status(conn) do
    status = ClusterStatus.get_cluster_status()
    Render.render_one({:ok, status}, conn)
  end

  def list_apis_status(conn) do
    with %Changeset{valid?: true} = changeset <- params_changeset(conn.query_params),
         disclosed_apis <- API.list_disclosed_apis(),
         disclosed_apis_ids <- Enum.map(disclosed_apis, fn %{id: id} -> id end),
         interval <- Changeset.get_change(changeset, :interval, "5 minutes"),
         latencies <- Analytics.aggregate_latencies(disclosed_apis_ids, interval) do
      render_apis_status(conn, disclosed_apis, latencies)
    else
      %Changeset{valid?: false} = changeset -> Response.send_validation_error(conn, changeset)
    end
  end

  def get_requests_metrics(%{query_params: query_params} = conn) do
    api_ids =
      query_params
      |> Map.get("api_ids", "")
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    with %Changeset{valid?: true} = changeset <- params_changeset(query_params),
         interval <- Changeset.get_change(changeset, :interval, "5 minutes"),
         latencies <- Analytics.aggregate_latencies(api_ids, interval),
         status_codes <- Analytics.aggregate_status_codes(api_ids, interval) do
      Render.render_one({:ok, %{
        latencies: latencies,
        status_codes: status_codes
      }}, conn)
    else
      %Changeset{valid?: false} = changeset -> Response.send_validation_error(conn, changeset)
    end
  end

  defp params_changeset(params) do
    types = %{
      interval: :string
    }

    {params, types}
    |> Changeset.cast(params, Map.keys(types))
    |> Changeset.validate_format(:interval, ~r/[0-9]{1,2} (day[s]?|hour[s]?|minute[s]?)/)
  end

  defp render_apis_status(conn, disclosed_apis, latencies) do
    latencies_by_api =
      Enum.reduce(latencies, %{}, fn %{api_id: api_id} = latency, acc ->
        case Map.fetch(acc, api_id) do
          :error ->
            Map.put(acc, api_id, [latency])
          {:ok, api_latencies} ->
            Map.put(acc, api_id, api_latencies ++ [latency])
        end
      end)

    disclosed_apis
    |> Enum.map(fn %{id: id, name: name, description: description, docs_url: docs_url, health: health} ->
      %{
        id: id,
        name: name,
        description: description,
        docs_url: docs_url,
        health: health,
        metrics: %{
          latencies: Map.get(latencies_by_api, id, [])
        }
      }
    end)
    |> Render.render_collection(conn)
  end
end
