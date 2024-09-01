defmodule MNDP.Manager do
  @moduledoc false
  use DynamicSupervisor

  alias MNDP.Server

  @spec start_link(any) :: GenServer.on_start()
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @spec start_child(String.t()) :: DynamicSupervisor.on_start_child()
  def start_child(ifname) do
    DynamicSupervisor.start_child(__MODULE__, {Server, ifname})
  end

  @spec stop_child(String.t()) :: :ok
  def stop_child(ifname) do
    Server.stop_server(ifname)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
