defmodule Gateway.LoggerTest do
  use Plug.Test
  use Gateway.AcceptanceCase

  alias Gateway.DB.Schemas.Log

  @random_url "random_url"
  @random_data %{"data" => "random"}

  defp get_header(response, header) do
    for {k, v} <- response.headers, k === header, do: v
  end

  test "check logger plug" do
    url = @random_url <> "?key=value"
    {:ok, response} = post(url, Poison.encode!(@random_data), :public)

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

  test "GET /requests/" do
    repeat_random_post(3)

    conn = :get
      |> conn("/requests")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    assert conn.status === 200

    body = Poison.decode! conn.resp_body
    assert length(body["data"]) === 3
  end

  test "GET /requests/:request_id" do
    id = random_post()
    |> get_resp_header("x-request-id")
    |> Enum.at(0) || ""

    conn = :get
      |> conn("/requests/" <> id)
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    assert conn.status === 200
    body = Poison.decode! conn.resp_body
    assert body["data"]["id"] === id
  end

  test "DELETE /requests/:request_id" do
    id = random_post()
    |> get_resp_header("x-request-id")
    |> Enum.at(0) || ""

    conn = :delete
      |> conn("/requests/" <> id)
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    expected_resp = %{
      meta: EView.Renders.Meta.render("object", conn),
      data: %{}
    }

    assert 200 == conn.status
    assert Poison.encode!(expected_resp) == conn.resp_body
  end

  defp random_post do
    :post
      |> conn(@random_url, Poison.encode!(@random_data))
      |> put_req_header("content-type", "application/json")
      |> Gateway.PublicRouter.call([])
  end

  defp repeat_random_post(1) do
    random_post()
  end
  defp repeat_random_post(count) do
    random_post()
    repeat_random_post(count - 1)
  end
end
