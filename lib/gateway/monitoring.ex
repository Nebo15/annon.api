defmodule Gateway.Monitoring do
  import Plug.Conn
  use Elixometer
  
  @unit :milli_seconds
  
  def init(opts) do
        opts
  end

  def call(conn, opts) do
    conn
    |> metric_name("request_count")
    |> update_counter(1)

    req_start_time = :erlang.monotonic_time(@unit)
    Plug.Conn.register_before_send conn, fn conn ->
      request_duration = :erlang.monotonic_time(@unit) - req_start_time
    
    conn 
    |> metric_name("request_duration")
    |> update_histogram(request_duration)
    
    conn
    end        
  end

  defp metric_name(conn, type) do
    path = conn.path_info
    |> Enum.reduce("", fn(x, acc) -> x <> "_" <> acc end)
    
    path <> "_" <> type
  end

end