#!/usr/bin/env elixir

# Run as host even if invoked with MIX_TARGET set
Mix.start()
:ok = Mix.target(:host)

Mix.install([
  {:mndp, "~> 0.1.0"},
  {:owl, "~> 0.12.0"}
])

MNDP.CLI.run()
