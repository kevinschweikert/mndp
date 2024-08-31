defmodule MNDP.Server do
  use GenServer

  @discovery_trigger <<0, 0, 0, 0>>
  @nerves? Mix.target() != :host

  require Logger

  def start_link(interface, callback, port \\ 5678) when is_function(callback) do
    GenServer.start_link(__MODULE__, %{
      interface: interface,
      callback: callback,
      port: port,
      socket: nil,
      discovered: MapSet.new()
    })
  end

  @impl GenServer
  def init(state) do
    socket_opts = [
      :binary,
      {:broadcast, true},
      {:active, true}
    ]

    socket_opts =
      if @nerves? do
        socket_opts ++ [bind_to_device: state.interface]
      else
        socket_opts ++ [ip: {0, 0, 0, 0}]
      end

    case :gen_udp.open(state.port, socket_opts) do
      {:ok, socket} ->
        {:ok, %{state | socket: socket}, {:continue, []}}

      {:error, :einval} ->
        Logger.error(
          "MDNP can't open port #{state.port} on #{state.interface}. Check permissions"
        )

        {:stop, :check_port_and_ifnames}

      {:error, other} ->
        {:stop, other}
    end
  end

  @impl GenServer
  def handle_continue(_, state) do
    Process.send(self(), :broadcast, [])
    send_packet(@discovery_trigger, state.socket, state.port)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:broadcast, state) do
    broadcast_discovery(state)
    Process.send_after(self(), :broadcast, 30_000)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:udp, _socket, _addr, _port, @discovery_trigger}, state) do
    broadcast_discovery(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:udp, _socket, _addr, _port, data}, state) do
    case MNDP.from_binary(data) do
      {:ok, mndp} ->
        # TODO: better uniqueness filter than string representation. Maybe seperate Device struct without header and uptime info
        unless MapSet.member?(state.discovered, to_string(mndp)) do
          discovered = MapSet.put(state.discovered, to_string(mndp))
          state.callback.(mndp)
          {:noreply, %{state | discovered: discovered}}
        else
          {:noreply, state}
        end

      _ ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def terminate(_reason, state) do
    :gen_udp.close(state.socket)
  end

  defp broadcast_discovery(state) do
    Logger.debug("MNDP Sending discovery packet on #{state.interface}")

    case MNDP.new(state.interface) do
      %MNDP{} = mndp ->
        mndp
        |> MNDP.to_binary()
        |> send_packet(state.socket, state.port)

      _ ->
        nil
    end
  end

  defp send_packet(data, socket, port) do
    :gen_udp.send(socket, {255, 255, 255, 255}, port, data)
  end
end
