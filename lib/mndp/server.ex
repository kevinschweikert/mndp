defmodule MNDP.Server do
  use GenServer

  @discovery_request <<0, 0, 0, 0>>

  require Logger

  def start_link(ifname) do
    {:ok, config} = Registry.meta(MNDP.Registry, :config)
    {:ok, interface} = MNDP.Interface.from_ifname(ifname)

    GenServer.start_link(
      __MODULE__,
      %{
        ifname: ifname,
        addr: interface.ip_v4,
        port: config.port,
        identity: config.identity,
        interval: config.interval,
        socket: nil
      },
      name: via_tuple(ifname)
    )
  end

  @spec stop_server(String.t()) :: :ok
  def stop_server(ifname) do
    GenServer.stop(via_tuple(ifname))
  catch
    :exit, {:noproc, _} ->
      # Ignore if the server already stopped. It already exited due to the
      # network going down.
      :ok
  end

  @impl GenServer
  def init(state) do
    socket_opts = [:binary, broadcast: true, active: true, reuseaddr: true, ip: state.addr]

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
        Logger.error("MDNP can't open port #{state.port} on #{state.ifname}. Check permissions")

        {:stop, :check_port_and_ifnames}

      {:error, other} ->
        Logger.error(
          "MDNP can't open socket with port #{state.port} on #{state.ifname}. Error: #{other}"
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
  def handle_info({:udp, _socket, addr, _port, @discovery_request}, state) do
    if addr != state.addr do
      broadcast_discovery(state)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:udp, _socket, addr, _port, data}, state) do
    if addr != state.addr do
      case MNDP.Packet.decode(data) do
        {:ok, mndp} ->
          if not is_self?(mndp, state) do
            # TODO:
          end

        _ ->
          nil
      end
    end

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

  defp is_self?(%MNDP{} = mndp, state) do
    mndp.identity == state.identity
  end

  defp send_packet(payload, state) do
    :gen_udp.send(state.socket, {255, 255, 255, 255}, state.port, payload)
  end

  defp via_tuple(ifname) do
    {:via, Registry, {MNDP.Registry, ifname}}
  end
end
