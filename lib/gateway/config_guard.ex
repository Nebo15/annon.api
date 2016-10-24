defmodule Gateway.ConfigGuard do
  @moduledoc """
    Plugin for JWT verifying and decoding
  """

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  # message: i_am_new, my_config_has_changed
  def send(message) do
    GenServer.call(__MODULE__, :reload_everyone_elses_config)
  end

  # expects: i_am_new, my_config_has_changed
  def receive(message) do
    GenServer.call(__MODULE__, :reload_my_config)
  end

  def handle_call(:i_am_new, _from, state) do
    # use libcluster to tell everyone that I am new

    {:reply, :ok, state}
  end
end
