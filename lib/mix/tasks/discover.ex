defmodule Mix.Tasks.Discover do
  @moduledoc "Discovers Devices with MNDP"
  @shortdoc "Disover devices"

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    [ifname | _] = args
    config = MNDP.Options.new()
    Registry.start_link(keys: :unique, name: MNDP.Registry, meta: [config: config])
    MNDP.Server.start_link(ifname)
    Process.sleep(:infinity)
  end
end
