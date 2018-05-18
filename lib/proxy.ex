defmodule Proxy do
  require Logger

  use GenServer

  defmodule State do
    @enforce_keys [:client, :upstream, :latency, :blackhole]
    defstruct [:client, :upstream, :latency, :blackhole]
  end

  def start(%State{client: client, upstream: upstream} = state) do
    with {:ok, proxy} <- GenServer.start(__MODULE__, state) do
      :ok = :gen_tcp.controlling_process(client, proxy)
      :ok = :gen_tcp.controlling_process(upstream, proxy)
      :ok = :inet.setopts(client, active: true)
      :ok = :inet.setopts(upstream, active: true)
      {:ok, proxy}
    else
      err -> err
    end
  end

  def init(%State{} = state) do
    {:ok, state}
  end

  def handle_info({:delayed, socket, data, arrival_time} = packet, state) do
    if current_time() - arrival_time > state.latency do
      other_socket(socket, state) |> :gen_tcp.send(data)
    else
      send(self(), packet)
    end

    {:noreply, state}
  end

  def handle_info({:tcp, socket, data}, state) do
    unless state.blackhole do
      send(self(), {:delayed, socket, data, current_time()})
    end

    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    Logger.info("TCP closed...")
    other_socket(socket, state) |> :gen_tcp.close()
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.error("TCP error: #{reason}")
    :gen_tcp.close(state.client)
    :gen_tcp.close(state.upstream)
    {:stop, :normal, state}
  end

  defp other_socket(socket, %State{client: client, upstream: upstream}) do
    case socket do
      ^client -> upstream
      ^upstream -> client
    end
  end

  defp current_time do
    :os.system_time(:millisecond)
  end
end
