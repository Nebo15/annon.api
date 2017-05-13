defmodule Annon.Requests.AnalyticsTest do
  @moduledoc false
  use Annon.DataCase, async: true
  alias Annon.Requests.Analytics
  alias Annon.RequestsFactory

  describe "aggregate_latencies/2" do
    test "returns aggregated list" do
      api_id = Ecto.UUID.generate()

      assert [] == Analytics.aggregate_latencies([api_id], {5, :minutes})

      # Seed API 1
      [
        # Tick one
        "2017-05-13T06:49:32.512796Z",
        "2017-05-13T06:49:32.512796Z",
        # Tick two
        "2017-05-13T06:44:32.512796Z",
        "2017-05-13T06:44:32.512796Z",
        # Tick three
        "2017-05-13T06:39:32.512796Z",
        "2017-05-13T06:39:32.512796Z",
      ]
      |> Enum.map(fn utc_datetime ->
        {:ok, datetime, 0} = DateTime.from_iso8601(utc_datetime)
        RequestsFactory.insert(:request,
          inserted_at: datetime,
          api: RequestsFactory.build(:api, id: api_id)
        )
      end)

      # Seed API 2
      api_id2 = Ecto.UUID.generate()
      [
        # Tick one
        "2017-05-13T06:50:32.512796Z",
        "2017-05-13T06:50:32.512796Z",
        # Tick two
        "2017-05-13T06:43:32.512796Z",
        "2017-05-13T06:44:32.512796Z",
        # Tick three
        "2017-05-13T06:39:32.512796Z",
        "2017-05-13T06:38:32.512796Z",
      ]
      |> Enum.map(fn utc_datetime ->
        {:ok, datetime, 0} = DateTime.from_iso8601(utc_datetime)
        RequestsFactory.insert(:request,
          inserted_at: datetime,
          api: RequestsFactory.build(:api, id: api_id2)
        )
      end)

      assert [
        %{
          api_id: ^api_id,
          avg_client_request_latency: _,
          avg_gateway_latency: _,
          avg_upstream_latency: _,
          tick: tick1
        },
        %{
          api_id: ^api_id,
          avg_client_request_latency: _,
          avg_gateway_latency: _,
          avg_upstream_latency: _,
          tick: tick2
        },
        %{
          api_id: ^api_id,
          avg_client_request_latency: _,
          avg_gateway_latency: _,
          avg_upstream_latency: _,
          tick: tick3
        }
      ] = Analytics.aggregate_latencies([api_id], {5, :minutes})

      {:ok, {{_, _, _}, {_, m1, _, _}}} = Ecto.DateTime.dump(tick1)
      {:ok, {{_, _, _}, {_, m2, _, _}}} = Ecto.DateTime.dump(tick2)
      {:ok, {{_, _, _}, {_, m3, _, _}}} = Ecto.DateTime.dump(tick3)

      assert (m1 - m2) == 5
      assert (m2 - m3) == 5

      assert 6 == length(Analytics.aggregate_latencies([api_id, api_id2], {5, :minutes}))
    end

    test "returns aggregated list by multiple apis" do

    end
  end

  describe "aggregate_status_codes/2" do
    test "returns aggregated list" do
      api_id = Ecto.UUID.generate()

      assert [] == Analytics.aggregate_status_codes([api_id], {5, :minutes})

      # Seed API 1
      [
        # Tick one
        "2017-05-13T06:49:32.512796Z",
        "2017-05-13T06:49:32.512796Z",
        # Tick two
        "2017-05-13T06:44:32.512796Z",
        "2017-05-13T06:44:32.512796Z",
        # Tick three
        "2017-05-13T06:39:32.512796Z",
        "2017-05-13T06:39:32.512796Z",
      ]
      |> Enum.map(fn utc_datetime ->
        {:ok, datetime, 0} = DateTime.from_iso8601(utc_datetime)
        RequestsFactory.insert(:request,
          inserted_at: datetime,
          api: RequestsFactory.build(:api, id: api_id)
        )
      end)

      # Seed API 2
      api_id2 = Ecto.UUID.generate()
      [
        # Tick one
        {"2017-05-13T06:50:32.512796Z", 200},
        {"2017-05-13T06:50:32.512796Z", 200},
        # Tick two
        {"2017-05-13T06:43:32.512796Z", 404},
        {"2017-05-13T06:44:32.512796Z", 500},
        # Tick three
        {"2017-05-13T06:39:32.512796Z", 200},
        {"2017-05-13T06:38:32.512796Z", 404},
      ]
      |> Enum.map(fn {utc_datetime, status_code} ->
        {:ok, datetime, 0} = DateTime.from_iso8601(utc_datetime)
        RequestsFactory.insert(:request,
          status_code: status_code,
          inserted_at: datetime,
          api: RequestsFactory.build(:api, id: api_id2)
        )
      end)

      assert [
        %{
          api_id: ^api_id,
          avg_client_request_latency: _,
          avg_gateway_latency: _,
          avg_upstream_latency: _,
          tick: tick1
        },
        %{
          api_id: ^api_id,
          avg_client_request_latency: _,
          avg_gateway_latency: _,
          avg_upstream_latency: _,
          tick: tick2
        },
        %{
          api_id: ^api_id,
          avg_client_request_latency: _,
          avg_gateway_latency: _,
          avg_upstream_latency: _,
          tick: tick3
        }
      ] = Analytics.aggregate_status_codes([api_id], {5, :minutes})
    end
  end
end
