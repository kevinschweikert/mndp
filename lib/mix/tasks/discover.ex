defmodule Mix.Tasks.Discover do
  @moduledoc "Discovers Devices with MNDP"
  @shortdoc "Disover devices"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Logger.configure(level: :info)
    IO.puts("Searching for devices...")
    MNDP.Listener.start_link([])
    Process.sleep(:timer.seconds(15))
    MNDP.print_discovered()
  end
end
