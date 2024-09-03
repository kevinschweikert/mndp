defmodule MNDP.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    config = Application.get_all_env(:mndp) |> MNDP.Options.new()

    children = [
      {Registry, keys: :unique, name: MNDP.Registry, meta: [config: config]},
      {MNDP.Manager, []},
      {MNDP.Listener, []},
      {config.if_monitor, excluded_ifnames: config.excluded_ifnames}
    ]

    opts = [strategy: :rest_for_one, name: MNDP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
