import Config

config :mndp,
  if_monitor: MNDP.InetMonitor

# Overrides for debugging and testing
#
# * udhcpc_handler: capture whatever happens with udhcpc
# * resolvconf: don't update the real resolv.conf
# * persistence_dir: use the current directory
# * bin_ip: just fail if anything calls ip rather that run it
config :vintage_net,
  udhcpc_handler: VintageNetTest.CapturingUdhcpcHandler,
  resolvconf: "/dev/null",
  persistence_dir: "./test_tmp/persistence",
  bin_ip: "false"

if Mix.env() == :test do
  # Allow Responders to still be created, but skip starting gen_udp
  # so tests can pass
  config :mndp,
    skip_socket: true
end
