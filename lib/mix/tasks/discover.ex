defmodule Mix.Tasks.Discover do
  @moduledoc "Discovers Devices with MNDP"
  @shortdoc "Disover devices"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    [ifname | _] = args
    MNDP.Server.start_link(ifname, &print_discovered/1)
    Process.sleep(:infinity)
  end

  defp print_discovered(mndp) do
    Mix.shell().info("#{mndp}")
  end
end
