defmodule MNDP.Options do
  @moduledoc """
  MNDP options

  MNDP is usually configured in a project's application environment
  (`config.ex`). If you don't set any configuration, this is the default:

  ```elixir
  config :mndp,
    identifier: :hostname,
    interval: :timer.seconds(30),
    ttl: :timer.minutes(1),
    port: 5678,
    excluded_ifnames: ["lo0", "lo", "ppp0", "wwan0", "__unknown"],
    ipv4_only: true,
    if_monitor: MNDP.VintageNetMonitor #if vintage_net is available, will fall back to `MNDP.InetMonitor`
  ```

  The configurable keys are:

  * `:identifier` - A name set in the discovery packet. Per default this is set to `:hostname`
  * `:ttl` - The default MNDP record time-to-live for discovered devices. The default of 60
    seconds is probably fine for most use. 
  * `:excluded_ifnames` - A list of network interfaces names to ignore. By
    default, `MDNP` will ignore loopback and cellular network interfaces.
  * `:ipv4_only` - Set to `true` to only respond on IPv4 interfaces. Since IPv6
    isn't fully supported yet, this is the default. 
  * `:if_monitor` - Set to `MNDP.VintageNetMonitor` when using Nerves or
    `MNDP.InetMonitor` elsewhere.  The default is `MNDP.VintageNetMonitor`.

  Some options are modifiable at runtime. Functions for modifying these are in
  the `MNDP` module.
  """

  require Logger

  @default_identifier :hostname
  @default_interval :timer.seconds(30)
  @default_ttl :timer.seconds(60)
  @default_port 5678
  @default_excluded_ifnames ["lo0", "lo", "ppp0", "wwan0", "__unknown"]
  @default_ipv4_only true

  defstruct identifier: @default_identifier,
            interval: @default_interval,
            ttl: @default_ttl,
            port: @default_port,
            if_monitor: nil,
            excluded_ifnames: @default_excluded_ifnames,
            ipv4_only: @default_ipv4_only

  @typedoc false
  @type t :: %__MODULE__{
          identifier: String.t(),
          interval: pos_integer(),
          ttl: pos_integer(),
          port: 0..65_536,
          if_monitor: module(),
          excluded_ifnames: [String.t()],
          ipv4_only: boolean()
        }

  @doc false
  @spec new(Enumerable.t()) :: t()
  def new(enumerable \\ %{}) do
    opts = Map.new(enumerable)

    identifier = get_identifier(opts)
    interval = Map.get(opts, :interval, @default_interval)
    ttl = Map.get(opts, :ttl, @default_ttl)
    port = Map.get(opts, :port, @default_port)
    if_monitor = Map.get(opts, :if_monitor, default_if_monitor())
    excluded_ifnames = Map.get(opts, :excluded_ifnames, @default_excluded_ifnames)
    ipv4_only = Map.get(opts, :ipv4_only, @default_ipv4_only)

    %__MODULE__{
      identifier: identifier,
      interval: interval,
      ttl: ttl,
      port: port,
      if_monitor: if_monitor,
      excluded_ifnames: excluded_ifnames,
      ipv4_only: ipv4_only
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

  defp get_identifier(opts) do
    Map.get(opts, :identifier, @default_identifier) |> resolve_identifier()
  end

  defp resolve_identifier(:hostname) do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  defp resolve_identifier(mdns_name) when is_binary(mdns_name), do: mdns_name

  defp resolve_identifier(_other) do
    raise RuntimeError, "Identifier must be :hostname or a string"
  end
end
