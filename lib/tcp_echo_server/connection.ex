defmodule TCPEchoServer.Connection do
  use GenServer

  require Logger

  @spec start_link(:gen_tcp.socket()) :: GenEvent.on_start()
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  defstruct socket: nil, buffer: <<>>

  @impl true
  def init(socket) do
    {:ok, %__MODULE__{socket: socket}}
  end

  @impl true
  def handle_info(msg, state)

  def handle_info({:tcp, socket, data}, %__MODULE__{socket: socket} = state) do
    state =
      state.buffer
      |> update_in(&(&1 <> data))
      |> handle_new_data()

    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, %__MODULE__{socket: socket} = state) do
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, socket, reason}, %__MODULE__{socket: socket} = state) do
    Logger.error("TCP socket error: #{inspect(reason)}")
    {:stop, :normal, state}
  end

  defp handle_new_data(%__MODULE__{} = state) do
    case String.split(state.buffer, "\n", parts: 2) do
      [line, rest] ->
        :gen_tcp.send(state.socket, line <> "\n")

        state.buffer
        |> put_in(rest)
        |> handle_new_data()

      _other ->
        state
    end
  end
end
