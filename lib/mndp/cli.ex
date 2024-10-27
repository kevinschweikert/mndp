defmodule MNDP.CLI do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl GenServer
  def init(:ok) do
    {:ok, %{render_state: nil, timer: nil}, {:continue, :subscribe}}
  end

  @impl GenServer
  def handle_continue(:subscribe, state) do
    MNDP.subscribe()
    state = print_devices(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:mndp, _mndp}, state) do
    Process.cancel_timer(state.timer)
    state = print_devices(state)
    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    state = print_devices(state)
    {:noreply, state}
  end

  defp print_devices(state) do
    render_state = MNDP.print_discovered(state.render_state)
    timer = schedule_refresh()
    %{state | render_state: render_state, timer: timer}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, :timer.seconds(1))
  end

  def run() do
    Logger.configure(level: :info)
    Application.ensure_all_started(:mndp)

    IO.puts("""

    Press enter to end
    """)

    start_link([])

    _ = IO.gets("")
    :ok
  end
end
