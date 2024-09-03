defmodule MNDP.Packet do
  @moduledoc """
  functions for decoding and encoding the raw packet binary
  """

  @discovery_request <<0, 0, 0, 0>>

  @doc """
  decodes a binary into a `MNDP` struct
  """

  @spec decode(binary()) :: {:ok, MNDP.t()} | {:error, atom()}
  def decode(@discovery_request), do: {:error, :discovery_trigger_packet}

  def decode(<<type::8, ttl::8, seq_no::16, data::binary>>) do
    meta = [type: type, ttl: ttl, seq_no: seq_no]

    case decode_tlv(data, []) do
      {:ok, data} ->
        {:ok, struct(MNDP, Keyword.merge(meta, data))}

      error ->
        error
    end
  end

  def decode(_), do: {:error, :unknown_header}

  @doc """
  encodes a `MNDP` struct into a binary
  """

  @spec encode(MNDP.t()) :: binary()
  def encode(%MNDP{} = mndp) do
    tlv =
      mndp
      |> Map.to_list()
      |> Enum.map(&to_tlv/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn {type, _, _} -> type end, :asc)
      |> Enum.reduce(<<>>, fn field, acc -> acc <> encode_tlv(field) end)

    <<mndp.type::8, mndp.ttl::8, mndp.seq_no::16>> <> tlv
  end

  defp decode_tlv(<<>>, acc), do: {:ok, acc}

  defp decode_tlv(<<type::16, length::16, data::binary>>, acc) do
    case data do
      <<data::bytes-size(length), rest::binary>> ->
        decode_tlv(rest, [parse_tlv({type, length, data}) | acc])

      _ ->
        {:error, :expected_tlv_format}
    end
  end

  defp parse_tlv({1, _length, data}), do: {:mac, parse_mac(data)}
  defp parse_tlv({5, _length, data}), do: {:identity, data}
  defp parse_tlv({7, _length, data}), do: {:version, data}
  defp parse_tlv({8, _length, data}), do: {:platform, data}

  defp parse_tlv({10, length, data}) do
    <<seconds::unsigned-integer-little-size(length)-unit(8)>> = data
    {:uptime, seconds}
  end

  defp parse_tlv({11, _length, data}), do: {:software_id, data}
  defp parse_tlv({12, _length, data}), do: {:board, data}
  defp parse_tlv({14, _length, data}), do: {:unpack, parse_unpack(data)}
  defp parse_tlv({15, _length, data}), do: {:ip_v6, parse_ipv6(data)}
  defp parse_tlv({16, _length, data}), do: {:interface, data}
  defp parse_tlv({17, _length, data}), do: {:ip_v4, parse_ipv4(data)}

  defp parse_unpack(<<1>>), do: :none
  defp parse_unpack(_), do: nil
  defp parse_ipv4(<<q1::8, q2::8, q3::8, q4::8>>), do: {q1, q2, q3, q4}

  defp parse_ipv6(<<h1::16, h2::16, h3::16, h4::16, h5::16, h6::16, h7::16, h8::16>>),
    do: {h1, h2, h3, h4, h5, h6, h7, h8}

  defp parse_mac(<<m1::8, m2::8, m3::8, m4::8, m5::8, m6::8>>), do: [m1, m2, m3, m4, m5, m6]

  defp to_tlv({:mac, [m1, m2, m3, m4, m5, m6]}),
    do: {1, 6, <<m1::8, m2::8, m3::8, m4::8, m5::8, m6::8>>}

  defp to_tlv({_, nil}), do: nil
  defp to_tlv({:identity, data}), do: {5, byte_size(data), data}
  defp to_tlv({:version, data}), do: {7, byte_size(data), data}
  defp to_tlv({:platform, data}), do: {8, byte_size(data), data}
  defp to_tlv({:uptime, data}), do: {10, 4, <<data::little-32>>}
  defp to_tlv({:software_id, data}), do: {11, byte_size(data), data}
  defp to_tlv({:board, data}), do: {12, byte_size(data), data}
  defp to_tlv({:unpack, :none}), do: {14, 1, <<1::8>>}

  defp to_tlv({:ip_v6, {h1, h2, h3, h4, h5, h6, h7, h8}}),
    do: {15, 16, <<h1::16, h2::16, h3::16, h4::16, h5::16, h6::16, h7::16, h8::16>>}

  defp to_tlv({:interface, data}), do: {16, byte_size(data), data}
  defp to_tlv({:ip_v4, {q1, q2, q3, q4}}), do: {17, 4, <<q1::8, q2::8, q3::8, q4::8>>}

  defp to_tlv(_), do: nil

  defp encode_tlv({type, length, data}), do: <<type::16, length::16, data::binary>>
  defp encode_tlv(_), do: <<>>
end
