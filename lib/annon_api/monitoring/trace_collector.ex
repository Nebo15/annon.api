defmodule Annon.Monitoring.TraceCollector do
  alias Annon.Monitoring.Trace

  def send_span(conn) do
    span =
      conn
      |> Trace.start_span()
      |> Trace.end_span()

    spans = Poison.encode!([span])

    IO.inspect HTTPoison.post!("http://localhost:9411/api/v1/spans", spans, [
      {"content-type", "application/json"},
      {"accept", "application/json"},
    ])
  end
end
