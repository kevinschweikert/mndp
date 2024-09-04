defmodule Mix.Tasks.Discover do
  @moduledoc "Discovers Devices with MNDP"
  @shortdoc "Disover MNDP devices"

  use Mix.Task
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
        _ -> MNDP.table_discovered()
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

  @impl Mix.Task
  def run(_args) do
    Logger.configure(level: :info)
    Application.ensure_all_started(:owl)
    Registry.start_link(keys: :duplicate, name: MNDP.Subscribers)
    MNDP.Listener.start_link([])
    Mix.shell().info("")
    Mix.shell().info("Press any key to end")
    Mix.shell().info("")
    start_link([])
    Mix.shell().prompt("")
  end
end
