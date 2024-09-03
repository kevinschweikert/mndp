defmodule MNDP.Listener do
  use GenServer

  @discovery_request <<00, 00, 00, 00>>
  @discovery_request_winbox <<00, 00, 00, 00, 00, 06, 00, 00>>

  @gc_interval :timer.minutes(1)

  require Logger

  def list_discovered() do
    GenServer.call(__MODULE__, :discovered)
  end

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      %{
        port: Keyword.get(opts, :port, 5678),
        socket: nil,
        cache: %{}
      },
      name: __MODULE__
    )
  end

  @impl GenServer
  def init(state) do
    socket_opts = [:binary, active: true, ip: {0, 0, 0, 0}, reuseaddr: true, reuseport: true]

    case :gen_udp.open(state.port, socket_opts) do
      {:ok, socket} ->
        schedule_gc()
        {:ok, %{state | socket: socket}}

      {:error, :einval} ->
        Logger.error("MNDP can't open port #{state.port}. Check permissions")

        {:stop, :check_port}

      {:error, other} ->
        Logger.error("MNDP can't open socket with port #{state.port}. Error: #{other}")

        {:stop, other}
    end
  end

  @impl GenServer
  def handle_call(:discovered, _from, state) do
    {:reply, Map.values(state.cache), state}
  end

  @impl GenServer
  def handle_info({:udp, _socket, _addr, _port, data}, state)
      when data in [@discovery_request, @discovery_request_winbox] do
    # TODO: find out which sender is responsible for addr

    {:noreply, state}
  end

  def handle_info({:udp, _socket, addr, _port, data}, state) do
    with [] <- MNDP.registered(addr),
         {:ok, mndp} = MNDP.Packet.decode(data),
         mndp <- MNDP.seen_now(mndp) do
      Logger.debug("MNDP seen device #{mndp.identity}")
      {:noreply, update_cache(state, mndp)}
    else
      _ ->
        {:noreply, state}
    end
  end

  def handle_info(:gc, state) do
    cache = gc_cache(state.cache)
    schedule_gc()
    {:noreply, %{state | cache: cache}}
  end

  @impl GenServer
  def terminate(_reason, state) do
    :gen_udp.close(state.socket)
  end

  defp cache_key(%MNDP{mac: mac, identity: identity}) do
    {mac, identity}
  end

  defp update_cache(state, mndp) do
    cache =
      Map.update(state.cache, cache_key(mndp), mndp, &update_mndp(&1, mndp))
      |> gc_cache()

    %{state | cache: cache}
  end

  defp update_mndp(_existing, new) do
    new
  end

  defp gc_cache(cache) do
    Enum.reduce(cache, [], fn {key, mndp}, acc ->
      if DateTime.diff(DateTime.utc_now(), mndp.last_seen, :millisecond) < :timer.minutes(1) do
        [{key, mndp} | acc]
      else
        acc
      end
    end)
    |> Enum.into(%{})
  end

  defp schedule_gc, do: Process.send_after(self(), :gc, @gc_interval)
end
