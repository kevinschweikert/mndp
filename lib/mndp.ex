defmodule MNDP do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias MNDP.Interface

  @typedoc "representation of a hardware MAC address"
  @type mac() :: [byte()]

  @typedoc "seconds since start"
  @type uptime() :: non_neg_integer()

  @typedoc "a MNDP packet struct"
  @type t() :: %__MODULE__{
          type: integer(),
          ttl: integer(),
          seq_no: non_neg_integer(),
          mac: mac(),
          identity: String.t(),
          version: String.t(),
          platform: String.t(),
          uptime: uptime(),
          software_id: String.t(),
          board: String.t(),
          unpack: :none | nil,
          interface: String.t(),
          ip_v4: :inet.ip4_address(),
          ip_v6: :inet.ip6_address(),
          last_seen: DateTime.t()
        }

  @typedoc "field overrides for the MNDP struct generation"
  @type overrides() :: [
          identity: String.t(),
          version: String.t(),
          platform: String.t(),
          uptime: (-> uptime()),
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

  # protocol "Type:8,TTL:8,SEQ:16,TLV TYPE:16,TLV LENGTH:16,TLV DATA:64"
  @doc """
  Decdes a binary to a `MNDP` struct.

  The structure of a MNDP packet looks like this

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |     TYPE      |      TTL      |              SEQ              |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |           TLV TYPE            |          TLV LENGTH           |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                               |
      +                           TLV DATA                            +
      |                                                               |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

  * TYPE (8 bytes)
  * TTL (8 bytes)
  * SEQ (16 bytes)
  * TLV TYPE (16 bytes)
  * TLV LENGTH (16 bytes)
  * TLV DATA (TLV LENGTH)

  > #### Info {: .info}
  >
  > The header fields are set like this in RouterOS 6 but changes in RouterOS 7. Currently it is not guaranteed to be correct

  ## Examples

      iex> MNDP.decode(<<_>>)
      {:ok, %MNDP{}}

      iex> MNDP.decode(<<"unknown">>)
      {:error, :expected_tlv_format}
  """
  @spec decode(binary()) :: {:ok, t()} | {:error, atom()}
  defdelegate decode(binary), to: MNDP.Packet

  @doc """
  Ecnodes an `MNDP` stuct to a binary

  ## Examples

      iex> MNDP.encode(%MNDP{})
      <<...>>
  """
  @spec encode(t()) :: binary()
  defdelegate encode(mndp), to: MNDP.Packet

  @doc """
  List all the discovered devices withing configured TTL. See `MNDP.Options` for informations about how to modify the default settings
  """
  @spec list_discovered() :: [t()]
  defdelegate list_discovered, to: MNDP.Listener

  @doc """
  Will print the devices from `list_discovered/0` via `IO.puts`
  """
  @spec print_discovered(nil | MNDP.Render.t()) :: MNDP.Render.t()
  defdelegate print_discovered(module \\ %MNDP.Render{}), to: MNDP.Render

  @doc """
  Creates a new MNDP struct from an interface name or struct.

  ## Examples

      iex> MNDP.new("en0")
      {:ok, %MNDP{}}

      iex> MNDP.new("unknown interface")
      {:error, :interface_not_found} 
      
  """

  @spec new(Interface.t() | String.t(), overrides()) :: t() | {:error, atom()}
  def new(interface_or_ifname, overrides \\ [])

  def new(ifname, overrides) when is_binary(ifname) do
    with {:ok, interface} <- Interface.from_ifname(ifname) do
      new(interface, overrides)
    end
  end

  def new(%Interface{} = interface, overrides) do
    identity = Keyword.get(overrides, :identity, identity())
    version = Keyword.get(overrides, :version, version())
    platform = Keyword.get(overrides, :platform, platform())
    uptime = Keyword.get(overrides, :uptime, &uptime/0)
    software_id = Keyword.get(overrides, :software_id, software_id())
    board = Keyword.get(overrides, :board, board())

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

  @doc """
  Same as `MNDP.new/2` but raises on error
  """
  @spec new!(String.t(), overrides()) :: t()
  def new!(ifname, overrides \\ []) when is_binary(ifname) do
    with {:ok, interface} <- Interface.from_ifname(ifname),
         %MNDP{} = mndp <- new(interface, overrides) do
      mndp
    else
      {:error, reason} -> raise RuntimeError, "could not create MNDP packet, error: #{reason}"
    end
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

  @doc """
  Subscribe the current process to new MNDP packets from the listener. It will send a message with the type `{:mndp, MNDP.t()}`

  Ususally you do this in a process like a GenServer and the message can be handled like this

        def handle_info({:mndp, %MNDP{} = mndp}, state) do
          IO.inspect(mndp)
          {:noreply, state}
        end

  If you subscribe from an `IEx` shell you can flush the received messages with `IEx.Helpers.flush/0`. It is automatically imported and can be called with just `flush()`
  """
  @spec subscribe() :: :ok
  def subscribe() do
    Registry.register(MNDP.Subscribers, "subscribers", [])
    :ok
  end
end
