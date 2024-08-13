# MNDP - MikroTik Neighbor Discovery Protocol

An Elixir implementation for the [MikroTik Neighbor Discovery Protocol](https://help.mikrotik.com/docs/display/ROS/Neighbor+discovery).

Currently it is possible to decode and encode from/to a binary packet.

Encoding: 

```elixir
%MNDP{
  type: 71,
  ttl: 0,
  seq_no: 0,
  mac: [116, 77, 40, 145, 13, 47],
  identity: "MikroTik",
  version: "7.15.3 (stable) 2024-07-24 10:39:01",
  platform: "MikroTik",
  uptime: 2300,
  software_id: "H792-MXJ3",
  board: "RBD52G-5HacD2HnD",
  unpack: :none,
  ip_v6: {65152, 0, 0, 0, 30285, 10495, 65169, 3375},
  interface: "bridge/ether2",
  ip_v4: {192, 168, 88, 1},
  received_at: nil
}
|> MNDP.to_binary()
```

Decoding: 

```elixir
iex> MNDP.from_binary(binary)
{:ok, 
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
}}

```

You can also start a `Listener` with a custom callback to discover devices like this

```elixir
MNDP.Listener.start_link(fn mndp -> IO.inspect(mndp) end)
```

## Todo / Ideas

- [ ] API to create MNDP struct from scratch with custom data
- [ ] Create MNDP struct from system and interface
- [x] Better handling for `header` and `seq_no` fields
- [x] Better error handling
- [ ] Test custom packets with [WinBox](https://help.mikrotik.com/docs/display/ROS/WinBox)
- [x] Listener to discover devices
- [ ] Sender to broadcast discovery packet
- [ ] Inspect protocol to make things like MAC address and IP adresses more readable


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

