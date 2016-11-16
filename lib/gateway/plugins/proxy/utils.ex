defmodule Gateway.Plugins.Proxy.Utils do
  def stream(path, headers, path_to_device) do
    {:ok, pid} = :hackney.request(:post, path, headers, :stream, [])

    send_body(pid, path_to_device)

    {:ok, _status, _headers, pid} = :hackney.start_response(pid)
    {:ok, response_body} = :hackney.body(pid)

    response_body
  end

  defp send_body(pid, req_body) do
    :ok = :hackney.send_body(pid, req_body) # TODO: read in chunks from path_to_device
  end
end
