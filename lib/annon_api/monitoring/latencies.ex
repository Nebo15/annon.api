defmodule Annon.Monitoring.Latencies do
  @moduledoc false

  defstruct client_request: nil,
            upstream: nil,
            gateway: nil
end
