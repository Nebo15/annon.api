defmodule Annon.Plugin.Request do
  @moduledoc """
  This module provides structure that goes trough Plugins execution pipeline.
  """
  defstruct conn: nil,
            start_time: nil,
            feature_requirements: %Annon.Plugin.FeatureRequirements{},
            api: nil,
            plugins: []
end
