defmodule Gateway.Plugins.Proxy.MultipartForm do
  @moduledoc """
  Facilities to contstruct parts of a multipart form.

  Supports constructing parts in a format, expected by hackney.
  (and inherited by HTTPoison).
  """

  def reconstruct_using(params) do
    params
    |> encode_query()
    |> List.flatten
    |> Enum.map(&build_part_from(&1))
  end

  defp encode_query(map, ancestors \\ [])
  defp encode_query(map, ancestors) do
    for {key, value} <- map do
      cond do
        match?(%{__struct__: _}, value) ->
          build_pair([key | ancestors], value)
        is_map(value) ->
          encode_query(value, [key|ancestors])
        true ->
          build_pair([key | ancestors], value)
      end
    end
  end

  defp build_pair(list, value) do
    [root | seq] = Enum.reverse(list)

    sequence_of_ancestors =
      seq
      |> Enum.map(&"[#{&1}]")
      |> Enum.join

    {to_string(root) <> sequence_of_ancestors, value}
  end

  defp build_part_from({key, %Plug.Upload{path: path, filename: filename, content_type: content_type}}) do
    extra_headers = [{"Content-Type", content_type}]
    disposition = {"form-data", [{"name", ~s("#{key}")}, {"filename", ~s("#{filename}")}]}

    {:file, path, disposition, extra_headers}
  end

  defp build_part_from(tuple), do: tuple
end
