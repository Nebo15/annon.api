defmodule Annon.Monitoring.Trace do
  alias Annon.Monitoring.Trace
  alias Annon.Monitoring.Trace.BinaryAnnotation
  alias Annon.Monitoring.Trace.Endpoint
  alias Plug.Conn

  defstruct traceId: nil,   # Randomly generated, unique for a trace, set on all spans within it. 16-32 chars
            name: nil,      # Span name in lowercase (e.g. rpc method)
            parentId: nil,  # Parent span id. 8-byte identifier encoded as 16 lowercase hex characters.
                            # Can be omitted or set to nil if span is the root span of a trace.
            id: nil,        # Id of current span, unique in context of traceId.
                            # 8-byte identifier encoded as 16 lowercase hex characters.
            timestamp: nil, # Epoch **microseconds** of the start of this span,
                            # possibly absent if this an incomplete span.
            duration: nil,  # Duration in **microseconds** of the critical path, if known.
                            # Durations of less than one are rounded up.
            debug: false,
            annotations: [],
            binaryAnnotations: []

  def start_span(%Conn{} = conn, opts \\ []) do
    request_id = get_request_id(conn, Ecto.UUID.generate())
    timestamp = System.monotonic_time() |> System.convert_time_unit(:native, :microseconds)
    endpoint = nil

    annotations =
      opts
      |> Keyword.get(:annotations, [])
      |> Enum.map(fn {key, value} -> %BinaryAnnotation{key: key, value: value, endpoint: endpoint} end)

    %Trace{
      traceId: request_id,
      name: "gateway request",
      id: Ecto.UUID.generate(),
      timestamp: timestamp,
      binaryAnnotations: annotations
    }
  end

  def end_span(%Trace{} = trace, opts \\ []) do
    duration = System.convert_time_unit(System.monotonic_time(), :native, :microseconds) - trace.timestamp
    endpoint = nil

    annotations =
      opts
      |> Keyword.get(:annotations, [])
      |> Enum.reduce(trace.annotations, fn {key, value}, annotations ->
        [%BinaryAnnotation{key: key, value: value, endpoint: endpoint}] ++ annotations
      end)

    %{trace |
      duration: duration,
      annotations: annotations
    }
  end

  defp get_request_id(conn, default) do
    case Conn.get_resp_header(conn, "x-request-id") do
      [] -> default
      [id | _] -> id
    end
  end
end
