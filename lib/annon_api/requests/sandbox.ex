defmodule Annon.Requests.Sandbox do
  @moduledoc """
  A plug to allow concurrent, transactional acceptance tests with Annon.Requests module.
  """
  import Plug.Conn

  def init(opts \\ []) do
    Keyword.get(opts, :sandbox, Ecto.Adapters.SQL.Sandbox)
  end

  def call(conn, sandbox) do
    conn
    |> get_req_header("user-agent")
    |> List.first
    |> extract_metadata
    |> allow_sandbox_access(sandbox, conn)
  end

  @doc """
  Returns metadata to associate with the session
  to allow the endpoint to acces the database connection checked
  out by the test process.
  """
  @spec metadata_for(Ecto.Repo.t | [Ecto.Repo.t], pid) :: map
  def metadata_for(repo_or_repos, pid) when is_pid(pid) do
    %{repo: repo_or_repos, owner: pid}
  end

  defp allow_sandbox_access(%{repo: repos, owner: owner}, sandbox, conn) do
    low_writer_pid = Process.whereis(Annon.Requests.LogWriter)

    Annon.Requests.LogWriter.subscribe(self())

    repos
    |> List.wrap()
    |> Enum.each(fn repo ->
      sandbox.allow(repo, owner, low_writer_pid)
    end)

    register_before_send(conn, fn conn ->
      Annon.Requests.LogWriter.unsubscribe(self())
      conn
    end)
  end
  defp allow_sandbox_access(_metadata, _sandbox, conn),
    do: conn

  defp extract_metadata(user_agent) when is_binary(user_agent) do
    ua_last_part = user_agent |> String.split("/") |> List.last
    case Regex.run(~r/BeamMetadata \((.*?)\)/, ua_last_part) do
      [_, metadata] -> parse_metadata(metadata)
      _             -> %{}
    end
  end
  defp extract_metadata(_), do: %{}

  defp parse_metadata(encoded_metadata) do
    encoded_metadata
    |> Base.url_decode64!
    |> :erlang.binary_to_term
    |> case do
         {:v1, metadata} -> metadata
         _               -> %{}
       end
  end
end
