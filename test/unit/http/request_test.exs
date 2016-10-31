defmodule Gateway.HTTP.RequestTest do
  use Gateway.UnitCase

  @random_url "random_url"
  @random_data %{"data" => "random"}

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

  test "GET /requests/" do
    repeat_random_post(3)

    conn = :get
      |> conn("/requests?limit=3")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    assert 200 == conn.status

    assert 3 == conn.resp_body
    |> Poison.decode!()
    |> Map.fetch!("data")
    |> length()
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
      meta: %{
        code: 200,
        description: "Resource was deleted"
      },
      data: %{}
    }

    assert conn.status === 200
    assert conn.resp_body == Poison.encode!(expected_resp)
  end
end
