req_headers = [
]

path = "http://requestb.in/1mvy1741"

method = :post

{:ok, pid} = :hackney.request(method, path, req_headers, :stream_multipart, [])

:hackney.send_multipart_body(pid, {:file, "/Users/gmile/.vimrc"})
:hackney.send_multipart_body(pid, {:file, "/Users/gmile/.bash_history"})

{:ok, _status, _headers, pid} = :hackney.start_response(pid)

{:ok, body} = :hackney.body(pid)
              |> IO.inspect
