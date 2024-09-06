defmodule MNDP.CoreMonitorTest do
  use ExUnit.Case, async: true

  alias MNDP.CoreMonitor

  test "adding IPs" do
    state =
      CoreMonitor.init([])
      |> CoreMonitor.set_ip_list("eth0", [{1, 2, 3, 4}, {1, 2, 3, 4, 5, 6, 7, 8}])
      |> CoreMonitor.set_ip_list("wlan0", [{10, 11, 12, 13}, {14, 15, 16, 17}])

    # IPv4 filtering is on by default
    assert state.todo == [
             {MNDP.Manager, :start_child, ["eth0", {1, 2, 3, 4}]},
             {MNDP.Manager, :start_child, ["wlan0", {10, 11, 12, 13}]},
             {MNDP.Manager, :start_child, ["wlan0", {14, 15, 16, 17}]}
           ]
  end

  test "removing IPs" do
    state =
      CoreMonitor.init([])
      |> CoreMonitor.set_ip_list("eth0", [{1, 2, 3, 4}, {5, 6, 7, 8}])
      |> CoreMonitor.set_ip_list("eth0", [{5, 6, 7, 8}])

    assert state.todo == [
             {MNDP.Manager, :start_child, ["eth0", {1, 2, 3, 4}]},
             {MNDP.Manager, :start_child, ["eth0", {5, 6, 7, 8}]},
             {MNDP.Manager, :stop_child, ["eth0", {1, 2, 3, 4}]}
           ]
  end

  test "applying the todo list works" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    state =
      CoreMonitor.init([])
      |> Map.put(:todo, [
        {Agent, :update, [agent, fn x -> x + 1 end]},
        {Agent, :update, [agent, fn x -> x + 1 end]}
      ])
      |> CoreMonitor.flush_todo_list()

    assert state.todo == []
    assert Agent.get(agent, fn x -> x end) == 2
  end

  test "filtering interfaces" do
    state =
      CoreMonitor.init(excluded_ifnames: ["wlan0"])
      |> CoreMonitor.set_ip_list("eth0", [{1, 2, 3, 4}, {1, 2, 3, 4, 5, 6, 7, 8}])
      |> CoreMonitor.set_ip_list("wlan0", [{10, 11, 12, 13}, {14, 15, 16, 17}])

    # IPv4 filtering is on by default
    assert state.todo == [
             {MNDP.Manager, :start_child, ["eth0", {1, 2, 3, 4}]}
           ]
  end

  test "remove unset ifnames" do
    state =
      CoreMonitor.init([])
      |> CoreMonitor.set_ip_list("eth0", [{1, 2, 3, 4}, {1, 2, 3, 4, 5, 6, 7, 8}])
      |> CoreMonitor.set_ip_list("wlan0", [{10, 11, 12, 13}, {14, 15, 16, 17}])
      |> CoreMonitor.flush_todo_list()

    state =
      state
      |> CoreMonitor.set_ip_list("wlan0", [{10, 11, 12, 13}])
      |> CoreMonitor.unset_remaining_ifnames(["wlan0"])

    # IPv4 filtering is on by default
    assert state.todo == [
             {MNDP.Manager, :stop_child, ["wlan0", {14, 15, 16, 17}]},
             {MNDP.Manager, :stop_child, ["eth0", {1, 2, 3, 4}]}
           ]
  end
end
