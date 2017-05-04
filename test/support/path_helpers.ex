defmodule Annon.PathHelpers do
  @moduledoc """
  This module provider path generation helpers for various entities in Management API.
  """

  def plugins_path(api_id),
    do: "apis/#{api_id}/plugins"

  def plugin_path(api_id, name),
    do: "#{plugins_path(api_id)}/#{name}"

  def apis_path,
    do: "apis"

  def api_path(api_id),
    do: "#{apis_path()}/#{api_id}"

  def requests_path,
    do: "requests"

  def request_path(request_id),
    do: "#{requests_path()}/#{request_id}"
end
