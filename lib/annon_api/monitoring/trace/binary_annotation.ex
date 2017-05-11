defmodule Annon.Monitoring.Trace.BinaryAnnotation do
  defstruct key: nil,
            value: nil,
            endpoint: %Annon.Monitoring.Trace.Endpoint{}
end
