defmodule AnnonMonitoring.MetricsCollector.Packet do
  @moduledoc false
  use Bitwise

  otp_release = :erlang.system_info(:otp_release)
  @addr_family if(otp_release >= '19', do: [1], else: [])

  def header({n1, n2, n3, n4}, port) do
    @addr_family ++ [
      band(bsr(port, 8), 0xFF),
      band(port, 0xFF),
      band(n1, 0xFF),
      band(n2, 0xFF),
      band(n3, 0xFF),
      band(n4, 0xFF)
    ]
  end

  def build(header, name, key, val, send_tags?, options) do
    [header, key, ?:, val,  ?|,  metric_type(name)]
    |> set_option(:sample_rate, options[:sample_rate])
    |> set_option(:tags, options[:tags], send_tags?)
  end

  metrics = %{
    counter: "c",
    gauge: "g",
    histogram: "h",
    timing: "ms",
    set: "s"
  }

  for {name, type} <- metrics do
    defp metric_type(unquote(name)), do: unquote(type)
  end

  defp set_option(packet, _kind, _sample_rate, _send_tags? \\ nil)

  defp set_option(packet, _kind, nil, _send_tags?),
    do: packet

  defp set_option(packet, :sample_rate, sample_rate, _send_tags?) when is_float(sample_rate),
    do: [packet | ["|@", :erlang.float_to_binary(sample_rate, [:compact, decimals: 2])]]

  defp set_option(packet, :tags, tags, false) when is_list(tags),
    do: packet

  defp set_option(packet, :tags, tags, true) when is_list(tags),
    do: [packet | ["|#", Enum.join(tags, ",")]]
end
