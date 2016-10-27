defmodule Gateway.Acceptance.Plug.LoggerTest do
  use Gateway.AcceptanceCase
  alias Gateway.Logger.DB.Models.LogRecord

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
    result = LogRecord.get_record_by([id: id])

    assert(result !== nil, "Logs are missing")
    uri_to_check = result.request
    |> prepare_params
    |> Map.get(:uri)
    assert(uri_to_check === "/" <> @random_url, "Invalid uri has been logged")
    
    body_to_check = result.request
    |> prepare_params
    |> Map.get(:body)
    assert(body_to_check === @random_data, "Invalid body has been logged")
  end
end
