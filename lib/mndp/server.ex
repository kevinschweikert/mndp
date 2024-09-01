defmodule MNDP.Server do
  use GenServer
  alias MNDP.Interface

  @discovery_request <<0, 0, 0, 0>>

  require Logger

  def start_link(ifname, opts) do
    interface = interface!(ifname)
    bind = Keyword.get(opts, :bind, true)
    port = Keyword.get(opts, :port, 5678)
    interval = Keyword.get(opts, :interval, 30_000)
    config = Keyword.get(opts, :config)

    GenServer.start_link(
      __MODULE__,
      %{
        interface: interface,
        port: port,
        socket: nil,
        bind?: bind,
        interval: interval,
        config: config
      }
    )
  end

  def child_spec([interface, opts]) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [interface, opts]}
    }
  end

  defp interface!(ifname) do
    case Interface.from_ifname(ifname) do
      {:ok, interface} -> interface
      {:error, reason} -> raise ArgumentError, "Could not create interface, #{inspect(reason)}"
    end
  end

  @impl GenServer
  def init(state) do
    socket_opts = [:binary, broadcast: true, active: true]

    socket_opts =
      if state.bind? do
        socket_opts ++ [bind_to_device: state.interface.ifname]
      else
        socket_opts
      end

    case :gen_udp.open(state.port, socket_opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}, {:continue, []}}

      {:error, :einval} ->
        Logger.error(
          "MDNP can't open port #{state.port} on #{state.interface.ifname}. Check permissions"
        )

        {:stop, :check_port_and_ifnames}

      {:error, other} ->
        {:stop, other}
    end
  end

  @impl GenServer
  def handle_continue(_, state) do
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
  def handle_info({:udp, _socket, _addr, _port, @discovery_request}, state) do
    broadcast_discovery(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:udp, _socket, _addr, _port, data}, state) do
    case MNDP.Packet.decode(data) do
      {:ok, mndp} ->
        if not is_self?(mndp, state) do
          notify_manager(mndp, state)
        end

      _ ->
        nil
    end

    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    :gen_udp.close(state.socket)
  end

  defp broadcast_discovery(state) do
    Logger.debug("MNDP Sending discovery packet on #{state.interface.ifname}")

    case MNDP.new(state.interface) do
      %MNDP{} = mndp ->
        mndp
        |> MNDP.Packet.encode()
        |> send_packet(state)

      _ ->
        nil
    end
  end

  defp is_self?(%MNDP{} = mndp, state) do
    mndp.mac == state.interface.mac
  end

  defp send_packet(payload, state) do
    :gen_udp.send(state.socket, {255, 255, 255, 255}, state.port, payload)
  end

  def notify_manager(mndp, state) do
    # {:ok, config} = Registry.meta(state.config.registry_name, :config)
    GenServer.call(state.config.manager_name, {:new_device, mndp})
  end
end
