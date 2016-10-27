defmodule Gateway.HTTP.Requests do
  @moduledoc """
  REST for Requests
  Documentation http://docs.osapigateway.apiary.io/#reference/requests
  """
  use Gateway.Helpers.CommonRouter
  import Gateway.Helpers.Cassandra
  import Gateway.Helpers.IP

  get "/" do
    result = conn
    |> get_input_paging_params
    |> execute_query(:select_all)
    records = result[:ok]
    output_paging_params = get_output_paging_params(conn, records)
    records
    |> modify_records
    |> render_show_response(%{paging: output_paging_params})
    |> send_response(conn)
  end

  get "/:request_id" do
    result = execute_query([%{id: request_id}], :select_by_id)
    result[:ok]
    |> Enum.at(0)
    |> modify_record
    |> render_request
    |> send_response(conn)
  end

  delete "/:request_id" do
    execute_query([%{id: request_id}], :delete_by_id)
    {:ok, %{}}
    |> render_delete_response
    |> send_response(conn)
  end

  defp get_limit(conn) do
    limit = conn.params["limit"] || 50
    limit
    |> to_string
    |> String.to_integer
  end

  defp get_input_paging_params(conn) do
    starting_after = conn.params["starting_after"] || ""
    ending_before = conn.params["ending_before"] || ""
    limit = get_limit conn
    [[starting_after, ending_before, limit]]
  end

  defp get_output_paging_params(conn, records) do
    first_record = Enum.at(records, 0)
    last_record = Enum.at(records, -1)
    %{
      starting_after: last_record["id"],
      ending_before: first_record["id"],
      limit: get_limit conn
    }
  end

  defp modify_date(timestamp) do
    timestamp
    |> DateTime.from_unix!(:milliseconds)
    |> DateTime.to_string
  end

  defp modify_record_part(record, key, converter) do
    converted_value = converter.(record[key])
    Map.put(record, key, converted_value)
  end

  defp modify_record(nil) do
    nil
  end

  defp modify_record(record) do
    record
    |> modify_record_part("created_at", &modify_date/1)
    |> modify_record_part("ip_address", &ip_to_string/1)
    |> modify_record_part("request", &Poison.decode!/1)
    |> modify_record_part("response", &Poison.decode!/1)
    |> modify_record_part("latencies", &Poison.decode!/1)
    |> modify_record_part("consumer", &Poison.decode!/1)
    |> modify_record_part("api", &Poison.decode!/1)
  end

  defp modify_records(records) do
    records
    |> Enum.map(fn(record) -> modify_record(record) end)
    |> Enum.map(fn(record) -> Map.drop(record, ["requesr", "response", "latencies", "consumer"]) end)
  end

  def render_request(nil), do: render_not_found_response("Request not found")
  def render_request(request), do: render_show_response(request)

  def send_response({code, resp}, conn) do
    send_resp(conn, code, resp)
  end
end
