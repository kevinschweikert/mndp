defmodule MNDP.CoreMonitor do
  # Adapted from https://github.com/nerves-networking/mdns_lite
  #
  # Copyright [yyyy] [name of copyright owner]
  #
  # Licensed under the Apache License, Version 2.0 (the "License");
  # you may not use this file except in compliance with the License.
  # You may obtain a copy of the License at
  #
  # http://www.apache.org/licenses/LICENSE-2.0
  #
  # Unless required by applicable law or agreed to in writing, software
  # distributed under the License is distributed on an "AS IS" BASIS,
  # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  # See the License for the specific language governing permissions and
  # limitations under the License.

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
          ip_list: %{String.t() => [:inet.ip_address()]},
          filter: ([:inet.ip_address()] -> [:inet.ip_address()]),
          todo: [mfa()]
        }

  @spec init([option()]) :: state()
  def init(opts) do
    excluded_ifnames = Keyword.get(opts, :excluded_ifnames, [])
    filter = &filter_by_ipv4/1

    %{
      excluded_ifnames: excluded_ifnames,
      ip_list: %{},
      filter: filter,
      todo: []
    }
  end

  @spec set_ip_list(state(), String.t(), [:inet.ip_address()]) :: state()
  def set_ip_list(%{} = state, ifname, ip_list) do
    if ifname in state.excluded_ifnames do
      # Ignore excluded interface
      state
    else
      current_list = Map.get(state.ip_list, ifname, [])
      new_list = state.filter.(ip_list)

      {to_remove, to_add} = compute_delta(current_list, new_list)

      new_todo =
        state.todo ++
          Enum.map(to_remove, &{MNDP.Manager, :stop_child, [ifname, &1]}) ++
          Enum.map(to_add, &{MNDP.Manager, :start_child, [ifname, &1]})

      %{state | todo: new_todo, ip_list: Map.put(state.ip_list, ifname, new_list)}
    end
  end

  @spec flush_todo_list(state()) :: state()
  def flush_todo_list(state) do
    Enum.each(state.todo, fn {m, f, a} -> apply(m, f, a) end)

    %{state | todo: []}
  end

  def unset_remaining_ifnames(state, new_ifnames) do
    Enum.reduce(known_ifnames(state), state, fn ifname, state ->
      if ifname not in new_ifnames do
        set_ip_list(state, ifname, [])
      else
        state
      end
    end)
  end

  defp known_ifnames(state) do
    Map.keys(state.ip_list)
  end

  defp compute_delta(old_list, new_list) do
    {old_list -- new_list, new_list -- old_list}
  end

  defp filter_by_ipv4(ip_list) do
    Enum.filter(ip_list, &:inet.is_ipv4_address/1)
  end
end
