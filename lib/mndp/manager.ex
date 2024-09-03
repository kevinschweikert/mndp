defmodule MNDP.Manager do
  @moduledoc false
  use DynamicSupervisor

  alias MNDP.Sender

  @spec start_link(any) :: GenServer.on_start()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec start_child(String.t(), :inet.ip4_address()) :: DynamicSupervisor.on_start_child()
  def start_child(ifname, address) do
    DynamicSupervisor.start_child(__MODULE__, {Sender, {ifname, address}})
  end

  @spec stop_child(String.t(), :inet.ip4_address()) :: :ok
  def stop_child(ifname, address) do
    Sender.stop_server(ifname, address)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
