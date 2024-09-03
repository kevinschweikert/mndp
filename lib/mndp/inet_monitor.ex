defmodule MNDP.InetMonitor do
  @moduledoc """
  Network monitor that uses Erlang's :inet functions

  Use this network monitor to detect new network interfaces and their
  IP addresses when not using Nerves. It regularly polls the system
  for changes so it's not as fast at starting MNDP servers as
  the `MNDP.VintageNetCoreMonitor` is. However, it works everywhere.

  See `MNDP.Options` for how to set your `config.exs` to use it.
  """

  use GenServer

  alias MNDP.CoreMonitor
  require Logger

  @scan_interval :timer.seconds(10)

  # Watch :net.getifaddrs/1 for IP address changes and update the active responders.

  @doc false
  @spec start_link([CoreMonitor.option()]) :: GenServer.on_start()
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    {:ok, CoreMonitor.init(args), 1}
  end

  @impl GenServer
  def handle_info(:timeout, state) do
    {:noreply, update(state), @scan_interval}
  end

  defp update(state) do
    get_all_ifnames()
    |> Enum.reduce(state, fn {ifname, ip_list}, state ->
      CoreMonitor.set_ip_list(state, ifname, ip_list)
    end)
    |> CoreMonitor.flush_todo_list()
  end

  defp get_all_ifnames() do
    case :net.getifaddrs(:inet) do
      {:ok, ifaddrs} ->
        Enum.map(ifaddrs, fn ifaddr -> {to_string(ifaddr.name), ifaddr.addr.addr} end)
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        |> Enum.to_list()

      _error ->
        []
    end
  end
end
