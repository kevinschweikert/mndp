defmodule MNDP.VintageNetMonitor do
  @moduledoc """
  Network monitor that using VintageNet

  Use this network monitor to detect new network interfaces and their
  IP addresses when using Nerves. It is the default.
  """
  use GenServer

  alias MNDP.Monitor

  @addresses_topic ["interface", :_, "addresses"]

  @spec start_link([Monitor.option()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(opts) do
    # VintageNet is an optional dependency. Optional dependencies aren't
    # guaranteed to be started in order. See
    # https://github.com/elixir-lang/elixir/issues/10433. To work around this,
    # try to start it.
    _ = Application.ensure_all_started(:vintage_net)

    VintageNet.subscribe(@addresses_topic)

    {:ok, Monitor.init(opts), {:continue, :initialization}}
  end

  @impl GenServer
  def handle_continue(:initialization, state) do
    new_state =
      VintageNet.match(@addresses_topic)
      |> Enum.reduce(state, &set_vn_address_reducer/2)

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({VintageNet, ["interface", ifname, "addresses"], _old, new, _}, state) do
    new_state = state |> set_vn_address(ifname, new)

    {:noreply, new_state}
  end

  defp set_vn_address_reducer({["interface", ifname, "addresses"], addresses}, state) do
    set_vn_address(state, ifname, addresses)
  end

  defp set_vn_address(state, ifname, nil) do
    # nil gets passed when the network interface goes away.
    Monitor.remove_interface(state, ifname)
  end

  defp set_vn_address(state, ifname, _addresses) do
    Monitor.add_interface(state, ifname)
  end
end
