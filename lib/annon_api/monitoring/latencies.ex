defmodule Annon.Monitoring.Latencies do
  @moduledoc false

  defstruct request_id: nil,
            client: nil,
            upstream: nil,
            gateway: nil
end
