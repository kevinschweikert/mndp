defmodule MNDP.Sender do
  @moduledoc """
  Sender to broadcast MNDP packets.

  The `Sender` will be typically started and stopped by the interface monitors (`MNDP.InetMonitor` or `MNDP.VintageNetMonitor`). 
  It will one process for each IP address for each interface.
  To exclude interfaces from this automation, see `MNDP.Options`.

  To start and stop a `MNDP.Server` manually the interface name and IP address to bind to is needed

  ## Examples

      iex> MNDP.Server.start_link({"en0", {10, 0, 0, 199}})
      {:ok, pid}

      iex> MNDP.Server.stop_server("en0", {10, 0, 0, 199})
      :ok
  """
  use GenServer

  require Logger

  @discovery_request <<00, 00, 00, 00>>

  @spec start_link({String.t(), :inet.ip_address()}) :: GenServer.on_start()
  def start_link({ifname, address}) do
    {:ok, config} = Registry.meta(MNDP.Registry, :config)

    GenServer.start_link(
      __MODULE__,
      %{
        ifname: ifname,
        addr: address,
        port: config.port,
        identity: config.identity,
        interval: config.interval,
        socket: nil
      },
      name: via_tuple({ifname, address})
    )
  end

  @doc "Stops the running server for a given interface and IP address"
  @spec stop_server(String.t(), :inet.ip4_address()) :: :ok
  def stop_server(ifname, address) do
    Logger.debug("MNDP stopping server for #{ifname}")
    GenServer.stop(via_tuple({ifname, address}))
  catch
    :exit, {:noproc, _} ->
      # Ignore if the server already stopped. It already exited due to the
      # network going down.
      :ok
  end

  @impl GenServer
  def init(state) do
    socket_opts = [
      :binary,
      broadcast: true,
      active: true,
      ip: state.addr,
      reuseaddr: true,
      reuseport: true
    ]

    socket_opts =
      case :os.type() do
        {:unix, :linux} ->
          socket_opts ++ [bind_to_device: state.ifname]

        {:unix, :darwin} ->
          # TODO!
          socket_opts

        {:unix, _} ->
          # TODO!
          socket_opts
      end

    case :gen_udp.open(state.port, socket_opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}, {:continue, :discovery_request}}

      {:error, :einval} ->
        Logger.error("MNDP can't open port #{state.port} on #{state.ifname}. Check permissions")

        {:stop, :check_port_and_ifnames}

      {:error, other} ->
        Logger.error(
          "MNDP can't open socket with port #{state.port} on #{state.ifname}. Error: #{other}"
        )

        {:stop, other}
    end
  end

  @impl GenServer
  def handle_continue(:discovery_request, state) do
    Process.send(self(), :broadcast, [])
    send_packet(@discovery_request, state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:broadcast, state) do
    broadcast_discovery(state)
    Process.send_after(self(), :broadcast, state.interval)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:udp, _socket, addr, _port, data}, state) do
    Logger.debug("MNDP unexpected message from #{inspect(addr)}: #{data}")
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    :gen_udp.close(state.socket)
  end

  defp broadcast_discovery(state) do
    Logger.debug("MNDP Sending discovery packet on #{state.ifname}")

    case MNDP.new(state.ifname) do
      %MNDP{} = mndp ->
        mndp
        |> MNDP.Packet.encode()
        |> send_packet(state)

      _ ->
        nil
    end
  end

  defp send_packet(payload, state) do
    :gen_udp.send(state.socket, {255, 255, 255, 255}, state.port, payload)
  end

  defp via_tuple(name) do
    {:via, Registry, {MNDP.Registry, name}}
  end
end
