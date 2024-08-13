defmodule MNDP do
  @moduledoc """
  The Mikrotik Neighbor Discovery Protocol
  """

  @type t() :: %__MODULE__{
          type: integer(),
          ttl: integer(),
          seq_no: non_neg_integer(),
          mac: [0..255],
          identity: String.t(),
          version: String.t(),
          platform: String.t(),
          uptime: non_neg_integer(),
          software_id: String.t(),
          board: String.t(),
          unpack: :none | nil,
          ip_v6: :inet.ip6_address(),
          interface: String.t(),
          ip_v4: :inet.ip4_address(),
          received_at: DateTime.t()
        }

  defstruct [
    :type,
    :ttl,
    :seq_no,
    :mac,
    :identity,
    :version,
    :platform,
    :uptime,
    :software_id,
    :board,
    :unpack,
    :ip_v6,
    :interface,
    :ip_v4,
    :received_at
  ]

  defmodule Tlv do
    @type t() :: %__MODULE__{
            type: non_neg_integer(),
            length: non_neg_integer(),
            data: binary()
          }
    defstruct [:type, :length, :data]
  end

  @spec from_binary(binary()) :: {:ok, t()} | {:error, atom()}
  def from_binary(<<0, 0, 0, 0>>), do: {:error, :discovery_trigger_packet}

  def from_binary(<<type::8, ttl::8, seq_no::16, data::binary>>) do
    meta = [type: type, ttl: ttl, seq_no: seq_no]

    case parse(data, []) do
      {:ok, data} ->
        {:ok, struct(__MODULE__, Keyword.merge(meta, data))}

      error ->
        error
    end
  end

  def from_binary(_), do: {:error, :unknown_header}

  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = mndp) do
    tlv =
      mndp
      |> Map.to_list()
      |> Enum.map(&encode/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn {type, _, _} -> type end, :asc)
      |> Enum.reduce(<<>>, fn field, acc -> acc <> to_tlv(field) end)

    <<mndp.type::8, mndp.ttl::8, mndp.seq_no::16>> <> tlv
  end

  defp parse(<<>>, acc), do: {:ok, acc}

  defp parse(<<type::16, length::16, data::binary>>, acc) do
    case data do
      <<data::bytes-size(length), rest::binary>> ->
        parse(rest, [decode({type, length, data}) | acc])

      _ ->
        {:error, :tlv_wrong_format}
    end
  end

  defp decode({1, _length, data}), do: {:mac, parse_mac(data)}
  defp decode({5, _length, data}), do: {:identity, data}
  defp decode({7, _length, data}), do: {:version, data}
  defp decode({8, _length, data}), do: {:platform, data}

  defp decode({10, length, data}) do
    <<seconds::unsigned-integer-little-size(length)-unit(8)>> = data
    {:uptime, seconds}
  end

  defp decode({11, _length, data}), do: {:software_id, data}
  defp decode({12, _length, data}), do: {:board, data}
  defp decode({14, _length, data}), do: {:unpack, parse_unpack(data)}
  defp decode({15, _length, data}), do: {:ip_v6, parse_ipv6(data)}
  defp decode({16, _length, data}), do: {:interface, data}
  defp decode({17, _length, data}), do: {:ip_v4, parse_ipv4(data)}

  defp parse_unpack(<<1>>), do: :none
  defp parse_unpack(_), do: nil
  defp parse_ipv4(<<q1::8, q2::8, q3::8, q4::8>>), do: {q1, q2, q3, q4}

  defp parse_ipv6(<<h1::16, h2::16, h3::16, h4::16, h5::16, h6::16, h7::16, h8::16>>),
    do: {h1, h2, h3, h4, h5, h6, h7, h8}

  defp parse_mac(<<m1::8, m2::8, m3::8, m4::8, m5::8, m6::8>>), do: [m1, m2, m3, m4, m5, m6]

  defp encode({:mac, [m1, m2, m3, m4, m5, m6]}),
    do: {1, 6, <<m1::8, m2::8, m3::8, m4::8, m5::8, m6::8>>}

  defp encode({:identity, data}), do: {5, byte_size(data), data}
  defp encode({:version, data}), do: {7, byte_size(data), data}
  defp encode({:platform, data}), do: {8, byte_size(data), data}
  defp encode({:uptime, data}), do: {10, 4, <<data::little-32>>}
  defp encode({:software_id, data}), do: {11, byte_size(data), data}
  defp encode({:board, data}), do: {12, byte_size(data), data}
  defp encode({:unpack, :none}), do: {14, 1, <<1::8>>}

  defp encode({:ip_v6, {h1, h2, h3, h4, h5, h6, h7, h8}}),
    do: {15, 16, <<h1::16, h2::16, h3::16, h4::16, h5::16, h6::16, h7::16, h8::16>>}

  defp encode({:interface, data}), do: {16, byte_size(data), data}
  defp encode({:ip_v4, {q1, q2, q3, q4}}), do: {17, 4, <<q1::8, q2::8, q3::8, q4::8>>}

  defp encode(_), do: nil

  defp to_tlv({type, length, data}), do: <<type::16, length::16, data::binary>>
  defp to_tlv(_), do: <<>>
end
