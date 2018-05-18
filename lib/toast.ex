defmodule Toast do
  require Logger

  defmodule Config do
    @enforce_keys [:listen_port, :upstream_port, :latency, :blackhole]
    defstruct [:listen_port, :upstream_port, :latency, :blackhole]
  end

  def start(%Config{listen_port: listen_port} = config) do
    spawn(fn ->
      case :gen_tcp.listen(listen_port, [:binary, active: false, reuseaddr: true]) do
        {:ok, socket} ->
          Logger.info("Listening on port #{listen_port}...")
          accept_loop(socket, config)

        {:error, reason} ->
          Logger.error("Listen error: #{reason}")
      end
    end)
  end

  def accept_loop(socket, %Config{upstream_port: upstream_port} = config) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        upstream = connect_upstream(upstream_port)
        proxy(client, upstream, config)
        accept_loop(socket, config)

      {:error, reason} ->
        Logger.error("Accept error: #{reason}")
    end
  end

  def proxy(client, upstream, %Config{latency: latency, blackhole: blackhole}) do
    {:ok, _proxy} =
      Proxy.start(%Proxy.State{
        client: client,
        upstream: upstream,
        latency: latency,
        blackhole: blackhole
      })
  end

  def connect_upstream(port) do
    case :gen_tcp.connect('localhost', port, [:binary, active: false]) do
      {:ok, upstream} ->
        upstream

      {:error, reason} ->
        Logger.error("Connect error: #{reason}")
    end
  end
end
