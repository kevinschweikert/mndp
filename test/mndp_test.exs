defmodule MNDPTest do
  use ExUnit.Case
  # doctest MNDP

  @packet <<97, 0, 0, 0, 0, 1, 0, 6, 116, 77, 40, 145, 13, 47, 0, 5, 0, 8, 77, 105, 107, 114, 111,
            84, 105, 107, 0, 7, 0, 35, 55, 46, 49, 53, 46, 51, 32, 40, 115, 116, 97, 98, 108, 101,
            41, 32, 50, 48, 50, 52, 45, 48, 55, 45, 50, 52, 32, 49, 48, 58, 51, 57, 58, 48, 49, 0,
            8, 0, 8, 77, 105, 107, 114, 111, 84, 105, 107, 0, 10, 0, 4, 220, 21, 0, 0, 0, 11, 0,
            9, 72, 55, 57, 50, 45, 77, 88, 74, 51, 0, 12, 0, 16, 82, 66, 68, 53, 50, 71, 45, 53,
            72, 97, 99, 68, 50, 72, 110, 68, 0, 14, 0, 1, 1, 0, 15, 0, 16, 254, 128, 0, 0, 0, 0,
            0, 0, 118, 77, 40, 255, 254, 145, 13, 47, 0, 16, 0, 13, 98, 114, 105, 100, 103, 101,
            47, 101, 116, 104, 101, 114, 50, 0, 17, 0, 4, 192, 168, 88, 1>>

  test "encode/1" do
    assert {:ok,
            %MNDP{
              type: 97,
              ttl: 0,
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
            }} ==
             MNDP.decode(@packet)
  end

  test "decode/1" do
    assert @packet ==
             %MNDP{
               type: 97,
               ttl: 0,
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
             |> MNDP.encode()
  end

  test "roundtrip from binary" do
    assert @packet ==
             MNDP.decode(@packet) |> then(fn {:ok, mndp} -> mndp end) |> MNDP.encode()
  end

  test "roundtrip to binary" do
    {:ok, mndp} =
      %MNDP{
        type: 97,
        ttl: 0,
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
      |> MNDP.encode()
      |> MNDP.decode()

    assert mndp.platform == "MikroTik"
    assert mndp.ip_v4 == {192, 168, 88, 1}
  end
end
