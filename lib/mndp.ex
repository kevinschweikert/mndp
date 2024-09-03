defmodule MNDP do
  @moduledoc """
  The Mikrotik Neighbor Discovery Protocol
  """

  alias MNDP.Interface

  @type t() :: %__MODULE__{
          type: integer(),
          ttl: integer(),
          seq_no: non_neg_integer(),
          mac: [0..255],
          identity: String.t(),
          version: String.t(),
          platform: String.t(),
          uptime: non_neg_integer(),
          software_id: String.t(),
          board: String.t(),
          unpack: :none | nil,
          interface: String.t(),
          ip_v4: :inet.ip4_address(),
          ip_v6: :inet.ip6_address(),
          last_seen: DateTime.t()
        }

  @type opts() :: [
          identity: String.t(),
          version: String.t(),
          platform: String.t(),
          uptime: (-> non_neg_integer()),
          software_id: String.t(),
          board: String.t()
        ]

  defstruct [
    :mac,
    :identity,
    :version,
    :platform,
    :uptime,
    :software_id,
    :board,
    :interface,
    :ip_v4,
    ip_v6: nil,
    unpack: :none,
    type: 0,
    ttl: 0,
    seq_no: 0,
    last_seen: nil
  ]

  defdelegate decode(binary), to: MNDP.Packet
  defdelegate encode(mndp), to: MNDP.Packet

  @spec new!(String.t(), opts()) :: t() | {:error, atom()}
  def new!(ifname, opts) when is_binary(ifname) do
    {:ok, interface} = Interface.from_ifname(ifname)
    new(interface, opts)
  end

  @spec new(Interface.t() | String.t(), opts()) :: t() | {:error, atom()}
  def new(interface_or_ifname, opts \\ [])

  def new(ifname, opts) when is_binary(ifname) do
    with {:ok, interface} <- Interface.from_ifname(ifname) do
      new(interface, opts)
    end
  end

  def new(%Interface{} = interface, opts) do
    identity = Keyword.get(opts, :identity, identity())
    version = Keyword.get(opts, :version, version())
    platform = Keyword.get(opts, :platform, platform())
    uptime = Keyword.get(opts, :uptime, &uptime/0)
    software_id = Keyword.get(opts, :software_id, software_id())
    board = Keyword.get(opts, :board, board())

    %__MODULE__{
      mac: interface.mac,
      identity: identity,
      version: version,
      platform: platform,
      uptime: uptime.(),
      software_id: software_id,
      board: board,
      interface: interface.ifname,
      ip_v4: interface.ip_v4
    }
  end

  # :inet.gethostname is always sucessful
  defp identity, do: :inet.gethostname() |> elem(1) |> to_string()
  defp uptime, do: :erlang.statistics(:wall_clock) |> elem(0) |> div(1000)
  defp board, do: :erlang.system_info(:system_architecture) |> to_string()

  if Mix.target() == :host do
    defp version, do: Application.spec(:mndp, :vsn) |> to_string()
    defp software_id, do: nil
    defp platform, do: "Elixir"
  else
    defp version, do: Nerves.Runtime.KV.get_active("nerves_fw_version")
    defp software_id, do: Nerves.Runtime.KV.get_active("nerves_fw_uuid")

    defp platform do
      sysname = "Nerves"
      release = Nerves.Runtime.KV.get_active("nerves_fw_product")
      version = Nerves.Runtime.KV.get_active("nerves_fw_version")
      "#{sysname} #{release} #{version}"
    end
  end

  @spec seen_now(t()) :: t()
  def seen_now(%__MODULE__{} = mndp) do
    %MNDP{mndp | last_seen: DateTime.utc_now()}
  end

  @spec registered(:inet.ip4_address()) :: [pid()]
  def registered(ip) do
    if not is_nil(Process.whereis(MNDP.Registry)) do
      Registry.select(MNDP.Registry, [{{{:_, ip}, :"$2", :_}, [], [:"$2"]}])
    else
      []
    end
  end

  def print_discovered do
    header = ["IDENTITY\tMAC\t\t\tIPV4\t\tINTERFACE\tUPTIME"]

    mndp =
      MNDP.Listener.list_discovered()
      |> Enum.map(fn mndp ->
        "#{mndp.identity}\t#{print_mac(mndp.mac)}\t#{print_ip(mndp.ip_v4)}\t#{mndp.interface}\t\t#{mndp.uptime}"
      end)

    (header ++ mndp) |> Enum.join("\n") |> IO.puts()
  end

  defp print_mac(mac) do
    mac |> Enum.map_join(":", &Integer.to_string(&1, 16))
  end

  defp print_ip(nil), do: "UNKNOWN"
  defp print_ip(ip), do: :inet.ntoa(ip)
end
