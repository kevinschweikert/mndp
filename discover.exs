#!/usr/bin/env elixir

# Run as host even if invoked with MIX_TARGET set
Mix.start()
Mix.target(:host)

Mix.install(
  [
    {:mndp, "~> 0.1.0"},
    {:owl, "~> 0.12.0"}
  ],
  start_applications: false
)

Application.ensure_all_started(:owl)
MNDP.CLI.run()
