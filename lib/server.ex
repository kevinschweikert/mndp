defmodule MNDP.Server do
  use GenServer

  @discovery_trigger <<0, 0, 0, 0>>

  def start_link(interfaces, callback, port \\ 5678) when is_function(callback) do
    GenServer.start_link(__MODULE__, %{
      interfaces: interfaces,
      callback: callback,
      port: port,
      socket: nil,
      discovered: MapSet.new()
    })
  end

  @impl GenServer
  def init(args) do
    {:ok, args, {:continue, []}}
  end

  @impl GenServer
  def handle_continue(_, state) do
    Process.send(self(), :broadcast, [])

    with {:ok, socket} <-
           :gen_udp.open(state.port, [:binary, ip: {0, 0, 0, 0}, active: true, broadcast: true]),
         :ok <- send_packet(@discovery_trigger, socket, state.port) do
      {:noreply, %{state | socket: socket}}
    else
      _ -> {:stop, :init, state}
    end
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
    for interface <- state.interfaces do
      case MNDP.new(interface) do
        {:ok, mndp} -> MNDP.to_binary(mndp) |> send_packet(state.socket, state.port)
        _ -> nil
      end
    end
  end

  defp send_packet(data, socket, port) do
    :gen_udp.send(socket, {255, 255, 255, 255}, port, data)
  end
end
