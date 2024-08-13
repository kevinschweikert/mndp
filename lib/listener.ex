defmodule MNDP.Listener do
  use GenServer

  def start_link(callback, port \\ 5678) when is_function(callback) do
    GenServer.start_link(__MODULE__, %{
      callback: callback,
      port: port,
      socket: nil
    })
  end

  @impl GenServer
  def init(args) do
    {:ok, args, {:continue, []}}
  end

  @impl GenServer
  def handle_continue(_, state) do
    with {:ok, socket} <-
           :gen_udp.open(state.port, [:binary, ip: {0, 0, 0, 0}, active: true, broadcast: true]),
         # trigger discovery packet
         :ok <- :gen_udp.send(socket, {255, 255, 255, 255}, state.port, <<0, 0, 0, 0>>) do
      {:noreply, %{state | socket: socket}}
    else
      _ -> {:stop, :init, state}
    end
  end

  @impl GenServer
  def handle_info({:udp, _socket, _addr, _port, data}, state) do
    case MNDP.from_binary(data) do
      {:ok, mndp} -> state.callback.(mndp)
      _ -> nil
    end

    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    :gen_udp.close(state.socket)
  end
end
