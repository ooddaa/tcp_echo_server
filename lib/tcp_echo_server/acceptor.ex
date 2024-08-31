defmodule TCPEchoServer.Acceptor do
  use GenServer

  require Logger

  @spec start_link(keyword()) :: GenEvent.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    port = Keyword.fetch!(opts, :port)

    listen_opts = [
      :binary,
      active: :once,
      exit_on_close: false,
      reuseaddr: true,
      backlog: 25,
      packet: :line
    ]

    case :gen_tcp.listen(port, listen_opts) do
      {:ok, listen_socket} ->
        Logger.info("started TCP echo server on port #{port}")
        send(self(), :accept)
        {:ok, listen_socket}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_info(:accept, listen_socket) do
    case :gen_tcp.accept(listen_socket, 2_000) do
      {:ok, socket} ->
        {:ok, pid} = TCPEchoServer.Connection.start_link(socket)
        :ok = :gen_tcp.controlling_process(socket, pid)
        send(self(), :accept)
        {:noreply, listen_socket}

      {:error, :timeout} ->
        send(self(), :accept)
        {:noreply, listen_socket}

      {:error, reason} ->
        {:noreply, reason, listen_socket}
    end
  end
end
