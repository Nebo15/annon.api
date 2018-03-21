defmodule Annon.Requests.AnalyticsTest do
  @moduledoc false
  use Annon.DataCase, async: true
  alias Annon.Requests.Analytics
  alias Annon.Factories.Requests, as: RequestsFactory

  describe "aggregate_latencies/2" do
    setup do
      api_id1 = Ecto.UUID.generate()
      api_id2 = Ecto.UUID.generate()

      [
        # Tick one
        {"2017-05-13T06:01:00.000000Z", 100, 98, 2},
        {"2017-05-13T06:04:00.000000Z", 102, 98, 4},
        # Tick two
        {"2017-05-13T06:05:00.000000Z", 110, 102, 8},
        {"2017-05-13T06:09:00.000000Z", 101, 100, 1},
        # Tick three
        {"2017-05-13T06:10:00.000000Z", 100, 100, 0},
        {"2017-05-13T06:13:57.000000Z", 101, 100, 1},
      ]
      |> Enum.map(fn {utc_datetime, client_request_latency, upstream_latency, gateway_latency} ->
        {:ok, datetime, 0} = DateTime.from_iso8601(utc_datetime)
        RequestsFactory.insert(:request,
          inserted_at: datetime,
          api: RequestsFactory.build(:api, id: api_id1),
          latencies: RequestsFactory.build(:latencies,
            gateway: gateway_latency,
            upstream: upstream_latency,
            client_request: client_request_latency
          )
        )
      end)

      [
        # Tick one
        {"2017-05-13T06:03:00.000000Z", 80, 78, 2},
        {"2017-05-13T06:04:00.000000Z", 202, 98, 104},
        # Tick two
        {"2017-05-13T06:07:00.000000Z", 110, 102, 8},
        {"2017-05-13T06:08:00.000000Z", 101, 100, 1},
        # Tick three
        {"2017-05-13T06:10:00.000000Z", 100, 100, 0},
        # Tick four
        {"2017-05-13T06:15:00.000000Z", 101, 100, 1},
      ]
      |> Enum.map(fn {utc_datetime, client_request_latency, upstream_latency, gateway_latency} ->
        {:ok, datetime, 0} = DateTime.from_iso8601(utc_datetime)
        RequestsFactory.insert(:request,
          inserted_at: datetime,
          api: RequestsFactory.build(:api, id: api_id2),
          latencies: RequestsFactory.build(:latencies,
            gateway: gateway_latency,
            upstream: upstream_latency,
            client_request: client_request_latency
          )
        )
      end)

      %{api_ids: [api_id1, api_id2]}
    end

    test "returns aggregated by api_id latencies list", %{api_ids: [api_id1, api_id2]} do
      assert [] == Analytics.aggregate_latencies([Ecto.UUID.generate()], "5 minutes")
      assert 7 == length(Analytics.aggregate_latencies([], "5 minutes"))
      assert 7 == length(Analytics.aggregate_latencies("5 minutes"))
      assert 7 == length(Analytics.aggregate_latencies([api_id1, api_id2], "5 minutes"))
    end

    test "aggregates by N minute intervals", %{api_ids: [api_id1, _api_id2]} do
      # 5 minutes
      assert [
        %{
          api_id: ^api_id1,
          tick: tick1
        },
        %{
          api_id: ^api_id1,
          tick: tick2
        },
        %{
          api_id: ^api_id1,
          tick: tick3
        }
      ] = Analytics.aggregate_latencies([api_id1], "5 minutes")

      {:ok, {{_, _, _}, {_, m1, _, _}}} = Ecto.DateTime.dump(tick1)
      {:ok, {{_, _, _}, {_, m2, _, _}}} = Ecto.DateTime.dump(tick2)
      {:ok, {{_, _, _}, {_, m3, _, _}}} = Ecto.DateTime.dump(tick3)

      assert (m1 - m2) == 5
      assert (m2 - m3) == 5

      # 10 minutes
      assert [
        %{
          api_id: ^api_id1,
          tick: tick1
        },
        %{
          api_id: ^api_id1,
          tick: tick2
        }
      ] = Analytics.aggregate_latencies([api_id1], "10 minutes")

      {:ok, {{_, _, _}, {_, m1, _, _}}} = Ecto.DateTime.dump(tick1)
      {:ok, {{_, _, _}, {_, m2, _, _}}} = Ecto.DateTime.dump(tick2)

      assert (m1 - m2) == 10

      # 1 hour
      assert [
        %{
          api_id: ^api_id1,
          tick: tick1
        }
      ] = Analytics.aggregate_latencies([api_id1], "1 hour")

      {:ok, {{_, _, _}, {6, _, _, _}}} = Ecto.DateTime.dump(tick1)

      # 3 days
      assert [
        %{
          api_id: ^api_id1,
          tick: tick1
        }
      ] = Analytics.aggregate_latencies([api_id1], "3 days")

      {:ok, {{_, _, 12}, {_, _, _, _}}} = Ecto.DateTime.dump(tick1)
    end

    test "calculates average latencies by 5 minute intervals", %{api_ids: [api_id1, _api_id2]} do
      assert [
        %{
          avg_client_request_latency: avg_client_request_latency1,
          avg_gateway_latency: avg_gateway_latency1,
          avg_upstream_latency: avg_upstream_latency1
        },
        %{
          avg_client_request_latency: avg_client_request_latency2,
          avg_gateway_latency: avg_gateway_latency2,
          avg_upstream_latency: avg_upstream_latency2
        },
        %{
          avg_client_request_latency: avg_client_request_latency3,
          avg_gateway_latency: avg_gateway_latency3,
          avg_upstream_latency: avg_upstream_latency3
        }
      ] = Analytics.aggregate_latencies([api_id1], "5 minutes")

      assert Decimal.to_float(avg_client_request_latency1) == 100.5
      assert Decimal.to_float(avg_client_request_latency2) == 105.5
      assert Decimal.to_float(avg_client_request_latency3) == 101

      assert Decimal.to_float(avg_upstream_latency1) == 100
      assert Decimal.to_float(avg_upstream_latency2) == 101
      assert Decimal.to_float(avg_upstream_latency3) == 98

      assert Decimal.to_float(avg_gateway_latency1) == 0.5
      assert Decimal.to_float(avg_gateway_latency2) == 4.5
      assert Decimal.to_float(avg_gateway_latency3) == 3
    end
  end

  describe "aggregate_status_codes/2" do
    setup do
      api_id1 = Ecto.UUID.generate()
      api_id2 = Ecto.UUID.generate()

      [
        # Tick one
        {"2017-05-13T06:01:00.000000Z", 200},
        {"2017-05-13T06:04:00.000000Z", 200},
        # Tick two
        {"2017-05-13T06:05:00.000000Z", 200},
        {"2017-05-13T06:09:00.000000Z", 404},
        # Tick three
        {"2017-05-13T06:10:00.000000Z", 500},
        {"2017-05-13T06:13:57.000000Z", 301},
      ]
      |> Enum.map(fn {utc_datetime, status_code} ->
        {:ok, datetime, 0} = DateTime.from_iso8601(utc_datetime)
        RequestsFactory.insert(:request,
          inserted_at: datetime,
          api: RequestsFactory.build(:api, id: api_id1),
          status_code: status_code
        )
      end)

      [
        # Tick one
        {"2017-05-13T06:03:00.000000Z", 200},
        {"2017-05-13T06:04:00.000000Z", 201},
        # Tick two
        {"2017-05-13T06:07:00.000000Z", 401},
        {"2017-05-13T06:08:00.000000Z", 500},
        # Tick three
        {"2017-05-13T06:10:00.000000Z", 200},
        # Tick four
        {"2017-05-13T06:15:00.000000Z", 404},
      ]
      |> Enum.map(fn {utc_datetime, status_code} ->
        {:ok, datetime, 0} = DateTime.from_iso8601(utc_datetime)
        RequestsFactory.insert(:request,
          inserted_at: datetime,
          api: RequestsFactory.build(:api, id: api_id2),
          status_code: status_code
        )
      end)

      %{api_ids: [api_id1, api_id2]}
    end

    test "returns aggregated list", %{api_ids: [api_id1, api_id2]} do
      assert [] == Analytics.aggregate_status_codes([Ecto.UUID.generate()], "5 minutes")
      assert 11 == length(Analytics.aggregate_status_codes([], "5 minutes"))
      assert 11 == length(Analytics.aggregate_status_codes("5 minutes"))
      assert 11 == length(Analytics.aggregate_status_codes([api_id1, api_id2], "5 minutes"))

      assert [
        %{api_id: ^api_id1,
          count: 1,
          status_code: 301,
          tick: tick1
        },
        %{
          api_id: ^api_id1,
          count: 1,
          status_code: 500,
          tick: tick1
        },
        %{
          api_id: ^api_id1,
          count: 1,
          status_code: 200,
          tick: tick2
        },
        %{
          api_id: ^api_id1,
          count: 1,
          status_code: 404,
          tick: tick2
        },
        %{
          api_id: ^api_id1,
          count: 2,
          status_code: 200,
          tick: _
        }
      ] = Analytics.aggregate_status_codes([api_id1], "5 minutes")
    end
  end
end
