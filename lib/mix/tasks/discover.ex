defmodule Mix.Tasks.Discover do
  @moduledoc "Discovers Devices with MNDP"
  @shortdoc "Disover MNDP devices"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    MNDP.CLI.run()
  end
end
