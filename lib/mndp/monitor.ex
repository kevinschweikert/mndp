defmodule MNDP.Monitor do
  def init(opts) do
    excluded_ifnames = Keyword.get(opts, :excluded_ifnames, [])

    %{
      excluded_ifnames: excluded_ifnames
    }
  end

  def add_interface(self, ifname) do
    if ifname in self.excluded_ifnames do
      self
    else
      MNDP.Manager.start_child(ifname)
    end
  end

  def remove_interface(self, ifname) do
    if ifname in self.excluded_ifnames do
      self
    else
      MNDP.Manager.stop_child(ifname)
    end
  end
end
