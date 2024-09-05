defmodule MNDP.Interface do
  @type t() :: %__MODULE__{
          ip_v4: :inet.ip4_address(),
          broadcast: :inet.ip4_address() | nil,
          mac: MNDP.mac() | nil
        }
  defstruct ifname: nil, ip_v4: nil, broadcast: nil, mac: nil

  @spec from_ifname(String.t()) :: {:ok, t()} | {:error, atom()}
  def from_ifname(ifname) do
    with {:ok, if_opts} <- get_interface(ifname),
         {:ok, ip_v4} <- get_ipv4(if_opts) do
      {:ok,
       %__MODULE__{
         ifname: ifname,
         mac: if_opts[:hwaddr],
         ip_v4: ip_v4,
         broadcast: if_opts[:broadaddr]
       }}
    end
  end

  defp get_interface(ifname) do
    with {:ok, interfaces} <- :inet.getifaddrs(),
         {_, if_opts} <-
           Enum.find(interfaces, fn {name, _} -> name == String.to_charlist(ifname) end) do
      {:ok, if_opts}
    else
      _ -> {:error, :interface_not_found}
    end
  end

  defp get_ipv4(if_opts) do
    with ip_v4s = Keyword.filter(if_opts, fn {_, value} -> :inet.is_ipv4_address(value) end),
         {:ok, ip_v4} <- Keyword.fetch(ip_v4s, :addr) do
      {:ok, ip_v4}
    else
      _ -> {:error, :ip_v4_not_found}
    end
  end
end
