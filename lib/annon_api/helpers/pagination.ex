defmodule Annon.Helpers.Pagination do
  @moduledoc """
  Functions related to paging
  """

  def page_info_from(params) do
    starting_after = Map.get(params, "starting_after")
    ending_before = Map.get(params, "ending_before")
    limit = get_limit(params, 50)

    cursors = %Ecto.Paging.Cursors{starting_after: starting_after, ending_before: ending_before}

    %Ecto.Paging{limit: limit, cursors: cursors}
  end

  def get_limit(map, default \\ nil) do
    case Map.get(map, "limit") do
      nil ->
        default
      string ->
        case Integer.parse(string) do
          {integer, ""} -> integer
          _ -> string
        end
    end
  end
end
