defmodule Mix.Tasks.Discover do
  @moduledoc "Discovers Devices with MNDP"
  @shortdoc "Disover devices"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    MNDP.Server.start_link([], &print_discovered/1)
    Process.sleep(:infinity)
  end

  defp print_discovered(mndp) do
    Mix.shell().info("#{mndp}")
  end
end
