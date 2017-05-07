defmodule Annon.Plugin.Request do
  @moduledoc """
  This module provides structure that goes trough Plugins execution pipeline.
  """

  defstruct start_time: nil,
            feature_requirements: %{
              decode_body: false,
              log_consistency: false,
              modify_conn: false
            },
            api: nil,
            plugins: []
end
