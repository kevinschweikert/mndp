# MNDP - MikroTik Neighbor Discovery Protocol

An Elixir implementation for the [MikroTik Neighbor Discovery Protocol](https://help.mikrotik.com/docs/display/ROS/Neighbor+discovery).

Currently it is possible to decode and encode from/to a binary packet.

Encoding: 

```elixir
%MNDP{
  header: <<0x61, 0x0>>,
  seq_no: 0,
  mac: [0x74, 0x4D, 0x28, 0x91, 0x0D, 0x2F],
  identity: "MikroTik",
  version: "7.15.3 (stable) 2024-07-24 10:39:01",
  platform: "MikroTik",
  uptime: 5596,
  software_id: "H792-MXJ3",
  board: "RBD52G-5HacD2HnD",
  unpack: :none,
  ip_v6: {0xFE80, 0x0, 0x0, 0x0, 0x764D, 0x28FF, 0xFE91, 0xD2F},
  interface: "bridge/ether2",
  ip_v4: {192, 168, 88, 1}
}
|> MNDP.to_binary()
```

Decoding: 

```elixir
MNDP.from_binary!(binary)
> %MNDP{
  header: <<0x61, 0x0>>,
  seq_no: 0,
  mac: [0x74, 0x4D, 0x28, 0x91, 0x0D, 0x2F],
  identity: "MikroTik",
  version: "7.15.3 (stable) 2024-07-24 10:39:01",
  platform: "MikroTik",
  uptime: 5596,
  software_id: "H792-MXJ3",
  board: "RBD52G-5HacD2HnD",
  unpack: :none,
  ip_v6: {0xFE80, 0x0, 0x0, 0x0, 0x764D, 0x28FF, 0xFE91, 0xD2F},
  interface: "bridge/ether2",
  ip_v4: {192, 168, 88, 1}
}
```

## Todo / Ideas

- [ ] API to create MNDP struct from scratch with custom data
- [ ] Create MNDP struct from system and interface
- [ ] Better handling for `header` and `seq_no` fields
- [ ] Better error handling
- [ ] Test custom packets with [WinBox](https://help.mikrotik.com/docs/display/ROS/WinBox)
- [ ] Listener to discover devices
- [ ] Sender to broadcast discovery packet
- [ ] Inspect protocol to mace things like MAC address and IP adresses more readable


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mndp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mndp, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/mndp>.

