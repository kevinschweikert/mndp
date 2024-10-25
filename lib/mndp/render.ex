defmodule MNDP.Render do
  @moduledoc """
  Helpers for rendering the MNDP struct
  """

  @type t() :: %__MODULE__{
          printed_rows: [String.t()],
          first_run: boolean()
        }

  # TODO: keep track of terminal width and redraw header and divider when changed
  defstruct printed_rows: 0, first_run: true

  @mac_width String.length("1A:2B:3C:4D:5E:6F")
  @ip_width String.length("111.222.333.444")
  @version_width String.length("10.10.10")
  @identity_width String.length("nerves-abcd")

  # TODO: show more or less columns depending on terminal width instead of fixed list
  @headers [
    identity: @identity_width,
    mac: @mac_width,
    ip_v4: @ip_width,
    ifname: nil,
    version: @version_width,
    uptime: nil,
    seen: nil
  ]
  @cols length(@headers)

  @doc delegate_to: {MNDP, :print_discovered, 1}
  def print_discovered(module \\ %__MODULE__{})
  def print_discovered(nil), do: print_discovered()

  def print_discovered(%__MODULE__{} = module) do
    terminal_width = terminal_width() - 3 * (@cols + 1)

    static_width =
      Enum.reduce(@headers, 0, fn
        {_, nil}, acc -> acc
        {_, width}, acc -> acc + width
      end)

    flexible_cols_count = Enum.count(@headers, &is_nil(elem(&1, 1)))
    flexible_col_width = round((terminal_width - static_width) / flexible_cols_count)

    divider = String.duplicate("-", terminal_width) |> List.duplicate(@cols)
    rows = MNDP.list_discovered() |> to_rows()

    format =
      Enum.map_join(@headers, "|", fn
        {_, nil} -> " ~#{flexible_col_width}s "
        {_, width} -> " ~#{width}s "
      end)

    format = "|#{format}|~n"

    if module.first_run do
      :io.fwrite(format, Keyword.keys(@headers))
      :io.fwrite(format, divider)
    else
      for _row <- module.printed_rows do
        move_cursor_up(1)
        clear_line()
      end
    end

    for mndp <- rows do
      :io.fwrite(format, mndp)
    end

    %{module | first_run: false, printed_rows: rows}
  end

  def to_rows(mndps) do
    Enum.map(mndps, fn mndp ->
      [
        mndp.identity,
        print_mac(mndp.mac),
        print_ip(mndp.ip_v4),
        mndp.interface,
        mndp.version,
        "#{mndp.uptime}s",
        "#{DateTime.diff(DateTime.utc_now(), mndp.last_seen)}s ago"
      ]
    end)
  end

  defp move_cursor_up(n) do
    IO.write(IO.ANSI.cursor_up(n))
  end

  defp clear_line() do
    IO.write(IO.ANSI.clear_line())
  end

  defp terminal_width do
    case :io.columns() do
      {:ok, width} -> width
      _ -> 80
    end
  end

  defp print_mac(mac) do
    mac |> Enum.map_join(":", &Integer.to_string(&1, 16))
  end

  defp print_ip(ip) do
    case :inet.ntoa(ip) do
      {:error, :einval} -> "unknown"
      address -> address |> to_string()
    end
  end
end
