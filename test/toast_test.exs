defmodule ToastTest do
  use ExUnit.Case

  test "listens and proxies to upstream" do
    {:ok, socket} = :gen_tcp.listen(4321, [:binary, active: false, reuseaddr: true])

    toast =
      Toast.start(%Toast.Config{
        listen_port: 1234,
        upstream_port: 4321,
        latency: 0,
        blackhole: false
      })

    {:ok, downstream1} = :gen_tcp.connect('localhost', 1234, [:binary, active: false])
    {:ok, upstream1} = :gen_tcp.accept(socket)

    {:ok, downstream2} = :gen_tcp.connect('localhost', 1234, [:binary, active: false])
    {:ok, upstream2} = :gen_tcp.accept(socket)

    :ok = :gen_tcp.send(downstream1, "from downstream")
    assert {:ok, "from downstream"} == :gen_tcp.recv(upstream1, 0, 10)
    :ok = :gen_tcp.send(upstream1, "from upstream")
    assert {:ok, "from upstream"} == :gen_tcp.recv(downstream1, 0, 10)

    :ok = :gen_tcp.send(downstream2, "from downstream")
    assert {:ok, "from downstream"} == :gen_tcp.recv(upstream2, 0, 10)
    :ok = :gen_tcp.send(upstream2, "from upstream")
    assert {:ok, "from upstream"} == :gen_tcp.recv(downstream2, 0, 10)

    :gen_tcp.close(socket)
    Process.exit(toast, :kill)
  end
end
