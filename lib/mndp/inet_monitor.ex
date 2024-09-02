defmodule MNDP.InetMonitor do
  @moduledoc """
  Network monitor that uses Erlang's :inet functions

  Use this network monitor to detect new network interfaces and their
  IP addresses when not using Nerves. It regularly polls the system
  for changes so it's not as fast at starting MNDP servers as
  the `MNDP.VintageNetMonitor` is. However, it works everywhere.

  See `MNDP.Options` for how to set your `config.exs` to use it.
  """

  use GenServer

  alias MNDP.Monitor
  require Logger

  @scan_interval :timer.seconds(10)

  # Watch :inet.getifaddrs/0 for IP address changes and update the active responders.

  @doc false
  @spec start_link([Monitor.option()]) :: GenServer.on_start()
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    {:ok, Monitor.init(args), 1}
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    {:noreply, update(state), @scan_interval}
  end

  defp update(state) do
    ifnames = get_all_ifnames()
    Monitor.set_interfaces(state, ifnames)
  end

  defp get_all_ifnames() do
    case :net.getifaddrs(:inet) do
      {:ok, ifaddrs} ->
        Enum.map(ifaddrs, fn ifaddr -> to_string(ifaddr.name) end)

      _error ->
        []
    end
  end
end
