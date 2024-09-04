# MNDP - MikroTik Neighbor Discovery Protocol

An Elixir implementation for the [MikroTik Neighbor Discovery Protocol](https://help.mikrotik.com/docs/display/ROS/Neighbor+discovery).


Discover devices

```bash
> mix discover
Searching for devices...
IDENTITY        MAC                     IPV4            INTERFACE       UPTIME
nerves-2a0c     BE:FE:21:C8:80:A1       172.31.199.73   usb0            1605
```

The application is automatically started and listening and broadcasting on all available IPv4 network interfaces. You can restrict the interfaces via config. See `MNDP.Options`. To use it just add the dependency to your project.

```elixir
def deps do
  [
    {:mndp, github: "kevinschweikert/mndp"}
  ]
end
```

To get the last discovered devices you can use `MNDP.Listener.list_discovered/0`.

You can decode and encode from and to a binary directly.

Encoding: 

```elixir
iex> MNDP.new!("en0") |> MNDP.encode()
<<...>>
```

Decoding: 

```elixir
iex> MNDP.decode(binary)
{:ok, %MNDP{}}
```


## Todo / Ideas

- [ ] Sequence numbering
- [x] Subscribe API
- [ ] Recognize when iface is down in `MNDP.InetMonitor`
- [ ] Answer discovery requests with correct `MNDP.Server` when received in `MNDP.Listener`
- [ ] Make everything configurable
- [ ] Add docs
- [ ] Add tests
- [ ] Better Logging
- [ ] Check licence
- [ ] With 0.1.0 add CHANGELOG

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

