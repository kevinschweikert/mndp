defmodule MNDP.CLI do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl GenServer
  def init(:ok) do
    {:ok, [], {:continue, :subscribe}}
  end

  @impl GenServer
  def handle_continue(:subscribe, state) do
    MNDP.subscribe()
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:mndp, _mndp}, socket) do
    {:noreply, socket}
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
