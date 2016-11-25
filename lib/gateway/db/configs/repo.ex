defmodule Gateway.DB.Configs.Repo do
  use Ecto.Repo, otp_app: :gateway
  use Ecto.Pagging.Repo

  def log(%Ecto.LogEntry{query: sql, result: result, params: params} = entry) do
    require Logger
    Logger.debug("#{inspect self()} is running #{sql} with #{inspect params}. Got: #{inspect result}")

    color(self())

    entry
  end

  defp color(pid) do
    [[_, x]]= Regex.scan(~r/\.(.*)\./, self() |> :erlang.pid_to_list() |> to_string())
    require Integer

    i = String.to_integer(x)

    if Integer.is_odd(i) do
      IO.ANSI.green()
    else
      IO.ANSI.green()
    end
  end
end
