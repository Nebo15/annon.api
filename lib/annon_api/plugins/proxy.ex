defmodule Annon.Plugins.Proxy do
  @moduledoc """
  [Proxy](http://docs.annon.apiary.io/#reference/plugins/proxy) - is a core plugin that
  sends incoming request to an upstream back-ends.
  """
  use Annon.Plugin, plugin_name: :proxy
  import Annon.Helpers.IP
  alias Annon.Plugin.UpstreamRequest

  defdelegate validate_settings(changeset), to: Annon.Plugins.Proxy.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.Proxy.SettingsValidator

  def execute(%Conn{} = conn, %{api: api}, settings) do
    upstream_request = build_upstream_request(conn, api, settings)
    proxy_adapter = Annon.Plugins.Proxy.Adapters.HTTP

    request_start_time = System.monotonic_time()

    %{
      headers: resp_headers,
      body: resp_body,
      status_code: resp_status_code
    } = proxy_adapter.dispatch(upstream_request, conn)

    request_end_time = System.monotonic_time()
    upstream_latency = System.convert_time_unit(request_end_time - request_start_time, :native, :micro_seconds)

    resp_headers
    |> Enum.reduce(conn, fn
      {"x-request-id", _header_value}, conn -> conn
      {header_key, header_value}, conn -> Conn.put_resp_header(conn, String.downcase(header_key), header_value)
    end)
    |> Conn.assign(:latencies_upstream, upstream_latency)
    |> Conn.send_resp(resp_status_code, resp_body)
    |> Conn.halt
  end

  defp build_upstream_request(conn, %{request: %{path: api_path}}, settings) do
    %Conn{
      request_path: request_path,
      assigns: %{upstream_request: upstream_request},
      query_string: query_string
    } = conn

    strip_api_path? = Map.get(settings, "strip_api_path", false)
    proxy_path = Map.get(settings, "path", nil)
    upstream_scheme = Map.get(settings, "scheme", Atom.to_string(conn.scheme))
    upstream_host = Map.fetch!(settings, "host")
    upstream_port = Map.get(settings, "port", nil)
    upstream_path = UpstreamRequest.get_upstream_path(request_path, proxy_path, api_path, strip_api_path?)

    %{upstream_request |
      scheme: upstream_scheme,
      host: upstream_host,
      port: upstream_port,
      path: upstream_path,
      query_params: query_string
    }
    |> put_request_id_header(conn)
    |> put_connection_headers(conn)
    |> put_x_forwarded_for_header(conn)
    |> put_x_forwarded_proto_header(conn)
    |> put_x_consumer_scopes_header(conn)
    |> put_x_consumer_id_header(conn)
    |> put_additional_headers(settings)
    |> drop_stripped_headers(settings)
  end

  defp put_request_id_header(upstream_request, conn) do
    request_id =
      conn
      |> Conn.get_resp_header("x-request-id")
      |> Enum.at(0)

    UpstreamRequest.put_header(upstream_request, "x-request-id", request_id)
  end

  defp put_connection_headers(upstream_request, %Conn{req_headers: headers}) do
    protected_headers = Confex.get(:annon_api, :protected_headers)

    Enum.reduce(headers, upstream_request, fn {header, value}, upstream_request ->
      if header in protected_headers,
          do: upstream_request,
        else: UpstreamRequest.put_header(upstream_request, header, value)
    end)
  end

  defp put_additional_headers(upstream_request, %{"additional_headers" => headers}) do
    Enum.reduce(headers, upstream_request, fn header_obj, upstream_request ->
      [{header, value}] = Map.to_list(header_obj)
      UpstreamRequest.put_header(upstream_request, header, value)
    end)
  end
  defp put_additional_headers(upstream_request, _conn),
    do: upstream_request

  defp put_x_forwarded_for_header(upstream_request, %{remote_ip: remote_ip}),
    do: UpstreamRequest.put_header(upstream_request, "x-forwarded-for", ip_to_string(remote_ip))

  defp put_x_forwarded_proto_header(upstream_request, %{scheme: scheme}),
    do: UpstreamRequest.put_header(upstream_request, "x-forwarded-proto", Atom.to_string(scheme))

  def drop_stripped_headers(upstream_request, %{"strip_headers" => true, "headers_to_strip" => headers})
    when not is_nil(headers),
    do: Enum.reduce(headers, upstream_request, &UpstreamRequest.delete_header(&2, &1))
  def drop_stripped_headers(upstream_request, _settings),
    do: upstream_request

  # TODO: Move to scopes plugin
  defp put_x_consumer_scopes_header(upstream_request, %Conn{private: %{scopes: scopes}}) when not is_nil(scopes),
    do: UpstreamRequest.put_header(upstream_request, "x-consumer-scope", Enum.join(scopes, " "))
  defp put_x_consumer_scopes_header(upstream_request, _conn),
    do: upstream_request

  # TODO: Move to scopes plugin
  defp put_x_consumer_id_header(upstream_request, %Conn{private: %{consumer_id: consumer_id}})
    when not is_nil(consumer_id),
    do: UpstreamRequest.put_header(upstream_request, "x-consumer-id", consumer_id)
  defp put_x_consumer_id_header(upstream_request, _conn),
    do: upstream_request
end
