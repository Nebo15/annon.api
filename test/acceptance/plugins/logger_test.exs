defmodule Gateway.Acceptance.Plugins.LoggerTest do
  @moduledoc false
  use Plug.Test
  use Gateway.AcceptanceCase

  alias Gateway.DB.Schemas.Log

  @random_url Ecto.UUID.generate()
  @random_data %{"data" => "random"}

  defp get_header(response, header) do
    for {k, v} <- response.headers, k === header, do: v
  end

  test "logger_plugin" do
    response = "#{@random_url}?key=value"
    |> put_public_url()
    |> post!(@random_data)
    |> assert_status(404)

    id = response
    |> get_header("x-request-id")
    |> Enum.at(0)

    assert(id !== nil, "Plug RequestId is missing or has invalid position")
    result = Log.get_one_by([id: id])

    assert(result !== nil, "Logs are missing")

    uri_to_check = result.request
    |> Map.from_struct
    |> Map.get(:uri)

    assert(uri_to_check === "/" <> @random_url, "Invalid uri has been logged")

    assert result.request.query == %{"key"=>"value"}

    body_to_check = result.request
    |> Map.from_struct
    |> Map.get(:body)

    assert(body_to_check === @random_data, "Invalid body has been logged")
  end
end
