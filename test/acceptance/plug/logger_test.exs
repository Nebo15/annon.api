defmodule Gateway.Acceptance.Plug.LoggerTest do
  use Gateway.AcceptanceCase
  import Gateway.Helpers.Cassandra

  @random_url "random_url"
  @random_data %{"data" => "random"}

  defp get_header(response, header) do
    for {k, v} <- response.headers, k === header, do: v
  end

  test "check logger plug" do
    {:ok, response} = @random_url
    |> post(Poison.encode!(@random_data), :public)
    id = response
    |> get_header("x-request-id")
    |> Enum.at(0)
    assert(id !== nil, "Plug RequestId is missing or has invalid position")
    result = execute_query([%{id: id}], :select_by_id)
    record = result[:ok]
    |> Enum.at(0)
    assert(record !== nil, "Logs are missing")
    request = Poison.decode! record["request"]
    assert(request["uri"] === "/" <> @random_url, "Invalid uri has been logged")
    assert(request["body"] === @random_data, "Invalid body has been logged")
  end
end
