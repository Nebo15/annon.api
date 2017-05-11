defmodule Annon.Monitoring.Trace.Annotation do
  defstruct timestamp: nil,
            value: nil,
            endpoint: %Annon.Monitoring.Trace.Endpoint{}
end
