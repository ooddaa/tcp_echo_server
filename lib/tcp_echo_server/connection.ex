defmodule TCPEchoServer.Connection do
  use GenServer

  require Logger

  @spec start_link(:gen_tcp.socket()) :: GenEvent.on_start()
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  defstruct socket: nil

  @impl true
  def init(socket) do
    {:ok, %__MODULE__{socket: socket}}
  end

  @impl true
  def handle_info(msg, state)

  def handle_info({:tcp, socket, line}, %__MODULE__{socket: socket} = state) do
    :ok = :inet.setopts(socket, active: :once)
    :ok = :gen_tcp.send(socket, line)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, %__MODULE__{socket: socket} = state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, socket, reason}, %__MODULE__{socket: socket} = state) do
    Logger.error("TCP socket error: #{inspect(reason)}")
    {:stop, :normal, state}
  end
end
