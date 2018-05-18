defmodule ProxyTest do
  use ExUnit.Case

  test "proxies between two socket pairs" do
    {proxy, downstream, upstream} = create_proxied_socket_pair(latency: 0, blackhole: false)

    :ok = :gen_tcp.send(downstream, "from downstream")
    assert {:ok, "from downstream"} == :gen_tcp.recv(upstream, 0, 10)

    :ok = :gen_tcp.send(upstream, "from upstream")
    assert {:ok, "from upstream"} == :gen_tcp.recv(downstream, 0, 10)

    Process.exit(proxy, :normal)
  end

  test "blockholes data between two socket pairs" do
    {proxy, downstream, upstream} = create_proxied_socket_pair(latency: 0, blackhole: true)

    :ok = :gen_tcp.send(downstream, "from downstream")
    assert {:error, :timeout} == :gen_tcp.recv(upstream, 0, 10)

    :ok = :gen_tcp.send(upstream, "from upstream")
    assert {:error, :timeout} == :gen_tcp.recv(downstream, 0, 10)

    Process.exit(proxy, :normal)
  end

  test "applies latency between two socket pairs" do
    {proxy, downstream, upstream} = create_proxied_socket_pair(latency: 100, blackhole: false)

    before = :os.system_time(:millisecond)
    :ok = :gen_tcp.send(downstream, "from downstream")
    assert {:ok, "from downstream"} == :gen_tcp.recv(upstream, 0, 110)
    delta = :os.system_time(:millisecond) - before
    assert delta > 100

    before = :os.system_time(:millisecond)
    :ok = :gen_tcp.send(upstream, "from downstream")
    assert {:ok, "from downstream"} == :gen_tcp.recv(downstream, 0, 110)
    delta = :os.system_time(:millisecond) - before
    assert delta > 100

    Process.exit(proxy, :normal)
  end

  defp create_proxied_socket_pair(latency: latency, blackhole: blackhole) do
    {downstream_client, downstream_server} = create_socket_pair(1234)
    {upstream_client, upstream_server} = create_socket_pair(4321)

    {:ok, proxy} =
      Proxy.start(%Proxy.State{
        client: downstream_server,
        upstream: upstream_client,
        latency: latency,
        blackhole: blackhole
      })

    {proxy, downstream_client, upstream_server}
  end

  defp create_socket_pair(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    {:ok, client} = :gen_tcp.connect('localhost', port, [:binary, active: false])
    {:ok, server} = :gen_tcp.accept(socket)
    :ok = :gen_tcp.close(socket)
    {client, server}
  end
end
