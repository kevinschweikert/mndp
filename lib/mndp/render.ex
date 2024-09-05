defmodule MNDP.Render do
  @moduledoc """
  Helpers for rendering the MNDP struct
  """

  @doc false
  @spec to_owl_table([MNDP.t()]) :: Owl.Data.t()
  def to_owl_table(mndps) when is_list(mndps) do
    mndps
    |> Enum.map(&print_map/1)
    |> Owl.Table.new(divide_body_rows: true, sort_columns: fn _, _ -> false end)
  end

  @doc delegate_to: {MNDP, :print_discovered, 0}
  def print_discovered do
    MNDP.list_discovered()
    |> to_owl_table()
    |> Owl.Data.to_chardata()
    |> IO.puts()
  end

  defp print_map(%MNDP{} = mndp) do
    %{
      "IDENTITY" => mndp.identity,
      "MAC" => print_mac(mndp.mac),
      "IPV4" => print_ip(mndp.ip_v4),
      "INTERFACE" => mndp.interface,
      "VERSION" => mndp.version,
      "UPTIME" => to_string(mndp.uptime),
      "LAST SEEN" => "#{DateTime.diff(DateTime.utc_now(), mndp.last_seen)}s ago"
    }
  end

  defp print_mac(mac) do
    mac |> Enum.map_join(":", &Integer.to_string(&1, 16))
  end

  defp print_ip(ip) do
    case :inet.ntoa(ip) do
      {:error, :einval} -> "unknown"
      address -> address
    end
  end
end
