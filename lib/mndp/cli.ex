defmodule MNDP.CLI do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl GenServer
  def init(:ok) do
    Owl.LiveScreen.add_block(:discovered,
      state: :init,
      render: fn
        :init -> "Scanning for devices..."
        :update -> MNDP.list_discovered() |> MNDP.Render.to_owl_table()
      end
    )

    {:ok, [], {:continue, :subscribe}}
  end

  @impl GenServer
  def handle_continue(:subscribe, state) do
    MNDP.subscribe()
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:mndp, _mndp}, socket) do
    Owl.LiveScreen.update(:discovered, :update)
    {:noreply, socket}
  end

  def run() do
    Logger.configure(level: :info)
    Application.ensure_all_started(:mndp)
    Application.ensure_all_started(:owl)

    IO.puts("""

    Press enter to end
    """)

    start_link([])

    _ = IO.gets("")
    :ok
  end
end
