defmodule Annon.Plugin.UpstreamRequest do
  @moduledoc """

  """
  alias Annon.Plugin.UpstreamRequest

  defstruct scheme: nil,
            host: nil,
            port: nil,
            path: nil,
            headers: [],
            query_params: nil,
            fragment: nil

  @doc """
  Constructs upstream URL by UpstreamRequest schema.

  Raises `RuntimeError` if host or schema is not set.

  ## Examples

      iex> to_upstream_url(%UpstreamRequest{})
      "http://example.com:80/subpath?a=b#hello"
  """
  def to_upstream_url!(%UpstreamRequest{} = upstream_request) do
    %{
      scheme: scheme,
      host: host,
      port: port,
      path: path,
      query_params: query_params,
      fragment: fragment
    } = upstream_request

    unless scheme do
      raise "Upstream request scheme is not set."
    end

    unless host do
      raise "Upstream request host is not set."
    end

    "#{scheme}://#{host}:#{get_port(port, scheme)}/#{strip_leading_slash(path)}" <>
    "#{maybe_get_query_params(query_params)}#{maybe_get_fragment(fragment)}"
  end

  defp get_port(nil, scheme),
    do: scheme |> URI.default_port() |> get_port(scheme)
  defp get_port(port, _scheme) when is_number(port),
    do: Integer.to_string(port)
  defp get_port(port, _scheme) when is_binary(port),
    do: port

  defp strip_leading_slash("/" <> path),
    do: path
  defp strip_leading_slash(path) when is_binary(path),
    do: path
  defp strip_leading_slash(nil),
    do: ""

  defp maybe_get_query_params(nil),
    do: ""
  defp maybe_get_query_params(params) when is_map(params),
    do: "?" <> URI.encode_query(params)
  defp maybe_get_query_params(params) when is_binary(params),
    do: "?#{params}"

  defp maybe_get_fragment(nil),
    do: ""
  defp maybe_get_fragment(fragment) when is_binary(fragment),
    do: "##{fragment}"

  @doc """
  Constructs upstream path based on [Proxy Docs](http://docs.annon.apiary.io/#reference/plugins/proxy).
  """
  def get_upstream_path(request_path, "/", _api_path, false),
    do: request_path
  def get_upstream_path(request_path, proxy_path, _api_path, false),
    do: "#{proxy_path}#{request_path}"

  def get_upstream_path(request_path, "/", api_path, true) do
    api_path = String.trim_trailing(api_path, "/")
    case String.trim_leading(request_path, api_path) do
      "" ->
        "/"
      path ->
        path
    end
  end
  def get_upstream_path(request_path, proxy_path, api_path, true) do
    upstream_path = String.trim_leading(request_path, api_path)
    "#{proxy_path}#{upstream_path}"
  end
end
