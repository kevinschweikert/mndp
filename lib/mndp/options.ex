defmodule MNDP.Options do
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
  MNDP options

  MNDP is usually configured in a project's application environment
  (`config.ex`). If you don't set any configuration, this is the default:

  ```elixir
  config :mndp,
    identity: :hostname,
    interval: :timer.seconds(30),
    ttl: :timer.minutes(1),
    port: 5678,
    excluded_ifnames: ["lo0", "lo", "bridge0", "ppp0", "wwan0", "__unknown"],
    if_monitor: MNDP.VintageNetMonitor #if vintage_net is available, will fall back to `MNDP.InetMonitor`
  ```

  The configurable keys are:

  * `:identity` - A name set in the discovery packet. Per default this is set to `:hostname`
  * `:ttl` - The default MNDP record time-to-live for discovered devices. The default of 60
    seconds is probably fine for most use. 
  * `:excluded_ifnames` - A list of network interfaces names to ignore. By
    default, `MNDP` will ignore loopback and cellular network interfaces.
  * `:if_monitor` - Set to `MNDP.VintageNetMonitor` when using Nerves or
    `MNDP.InetMonitor` elsewhere.  The default is `MNDP.VintageNetMonitor`.

  Some options are modifiable at runtime. Functions for modifying these are in
  the `MNDP` module.
  """

  require Logger

  @default_identity :hostname
  @default_interval :timer.seconds(30)
  @default_ttl :timer.seconds(60)
  @default_port 5678
  @default_excluded_ifnames ["lo0", "lo", "bridge0", "ppp0", "wwan0", "__unknown"]

  defstruct identity: @default_identity,
            interval: @default_interval,
            ttl: @default_ttl,
            port: @default_port,
            if_monitor: nil,
            excluded_ifnames: @default_excluded_ifnames

  @typedoc false
  @type t :: %__MODULE__{
          identity: String.t(),
          interval: pos_integer(),
          ttl: pos_integer(),
          port: 0..65_536,
          if_monitor: module(),
          excluded_ifnames: [String.t()]
        }

  @doc false
  @spec new(Enumerable.t()) :: t()
  def new(enumerable \\ %{}) do
    opts = Map.new(enumerable)

    identity = get_identity(opts)
    interval = Map.get(opts, :interval, @default_interval)
    ttl = Map.get(opts, :ttl, @default_ttl)
    port = Map.get(opts, :port, @default_port)
    if_monitor = Map.get(opts, :if_monitor, default_if_monitor())
    excluded_ifnames = Map.get(opts, :excluded_ifnames, @default_excluded_ifnames)

    %__MODULE__{
      identity: identity,
      interval: interval,
      ttl: ttl,
      port: port,
      if_monitor: if_monitor,
      excluded_ifnames: excluded_ifnames
    }
  end

  defp default_if_monitor() do
    if has_vintage_net?() do
      MNDP.VintageNetMonitor
    else
      MNDP.InetMonitor
    end
  end

  defp has_vintage_net?() do
    Application.loaded_applications()
    |> Enum.find_value(fn {app, _, _} -> app == :vintage_net end)
  end

  defp get_identity(opts) do
    Map.get(opts, :identity, @default_identity) |> resolve_identity()
  end

  defp resolve_identity(:hostname) do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  defp resolve_identity(name) when is_binary(name), do: name

  defp resolve_identity(_other) do
    raise RuntimeError, "identity must be :hostname or a string"
  end
end
