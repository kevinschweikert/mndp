# MNDP - MikroTik Neighbor Discovery Protocol

An Elixir implementation for the [MikroTik Neighbor Discovery Protocol](https://help.mikrotik.com/docs/display/ROS/Neighbor+discovery).

You can start a `Server` with a list of interfaces and a custom callback to discover devices and respond with discovery packets

```elixir
MNDP.Server.start_link(["en0"], fn mndp -> IO.inspect(mndp) end)
```

You can also do decoding/encoding to/from binary:

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
}
|> MNDP.to_binary()
```

Decoding: 

```elixir
iex> MNDP.from_binary(binary)
{:ok, 
  %MNDP{
    mac: [116, 77, 40, 145, 13, 47],
    identity: "MikroTik",
    version: "7.15.3 (stable) 2024-07-24 10:39:01",
    platform: "MikroTik",
    uptime: 84736,
    software_id: "H792-MXJ3",
    board: "RBD52G-5HacD2HnD",
    interface: "bridge/ether2",
    ip_v4: {192, 168, 88, 1},
    ip_v6: {65152, 0, 0, 0, 30285, 10495, 65169, 3375},
    unpack: :none,
    type: 107,
    ttl: 6,
    seq_no: 0
  }
}
```


## Todo / Ideas

- [ ] API to create MNDP struct from scratch with custom data
- [x] Create MNDP struct from system and interface
- [x] Better handling for `header` and `seq_no` fields
- [x] Better error handling
- [x] Test custom packets with [WinBox](https://help.mikrotik.com/docs/display/ROS/WinBox)
- [x] Listener to discover devices
- [x] Sender to broadcast discovery packet
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

