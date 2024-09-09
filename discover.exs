#!/usr/bin/env elixir

# Run as host even if invoked with MIX_TARGET set
Mix.start()
Mix.target(:host)

Mix.install([
  {:mndp, github: "kevinschweikert/mndp", start_applications: false},
  {:owl, "~> 0.11.0"}
])

MNDP.CLI.run()
