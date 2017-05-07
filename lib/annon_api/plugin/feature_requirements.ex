defmodule Annon.Plugin.FeatureRequirements do
  @moduledoc """
  This module provides a struct that allows Plugins to set their requirements
  on a request processing.
  """
  defstruct decode_body: false,
            log_consistency: false,
            modify_conn: false
end
