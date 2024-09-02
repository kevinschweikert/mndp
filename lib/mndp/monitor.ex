defmodule MNDP.Monitor do
  @moduledoc """
  Core logic for network monitors

  This module contains most of the logic needed for writing a network monitor.
  It's only intended to be called from `MNDP.InetMonitor` and
  `MNDP.VintageNetMonitor`.
  """

  @typedoc """
  Monitor options

  * `:excluded_ifnames` - a list of network interface names to ignore
  """
  @type option() :: {:excluded_ifnames, [String.t()]}

  @typedoc false
  @type state() :: %{
          excluded_ifnames: [String.t()],
          ifnames: MapSet.t(String.t())
        }

  def init(opts) do
    excluded_ifnames = Keyword.get(opts, :excluded_ifnames, [])

    %{
      excluded_ifnames: excluded_ifnames,
      ifnames: MapSet.new()
    }
  end

  @spec add_interface(state(), String.t()) :: state()
  def add_interface(%{} = state, ifname) do
    old = state.ifnames

    new =
      MapSet.put(old, ifname) |> MapSet.reject(fn ifname -> ifname in state.excluded_ifnames end)

    {to_add, to_remove} = diff(old, new)
    start_server(to_add)
    stop_server(to_remove)

    %{state | ifnames: new}
  end

  @spec remove_interface(state(), String.t()) :: state()
  def remove_interface(%{} = state, ifname) do
    old = state.ifnames
    new = MapSet.delete(old, ifname)
    {to_add, to_remove} = diff(old, new)
    start_server(to_add)
    stop_server(to_remove)

    %{state | ifnames: new}
  end

  @spec set_interfaces(state(), [String.t()] | String.t()) :: state()
  def set_interfaces(%{} = state, ifnames) do
    ifnames = List.wrap(ifnames)
    old = state.ifnames

    new =
      MapSet.new(ifnames) |> MapSet.reject(fn ifname -> ifname in state.excluded_ifnames end)

    {to_add, to_remove} = diff(old, new)
    start_server(to_add)
    stop_server(to_remove)

    %{state | ifnames: new}
  end

  defp start_server(ifnames) do
    for ifname <- ifnames, do: MNDP.Manager.start_child(ifname)
  end

  defp stop_server(ifnames) do
    for ifname <- ifnames, do: MNDP.Manager.stop_child(ifname)
  end

  defp diff(old, new) do
    to_add = MapSet.difference(new, old)
    to_remove = MapSet.difference(old, new)
    {to_add, to_remove}
  end
end
