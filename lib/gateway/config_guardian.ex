defmodule Gateway.ConfigGuardian do
  def start_link() do
    :ignore
  end

  def reload_config() do
    GenServer.s
  end

  def handle_call(:reload_config, _from, _state) do
  end

  def handle_call(:reload_config, _from, _state) do
  end
end
