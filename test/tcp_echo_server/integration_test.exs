defmodule TCPEchoServerTest.IntegrationTest do
  use ExUnit.Case
  doctest TCPEchoServer

  test "sends back data" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])
    text = "smth\n"
    assert :ok = :gen_tcp.send(socket, text)
    assert {:ok, data} = :gen_tcp.recv(socket, 0, 500)
    assert data == text
  end

  test "sends back fragmented data" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])
    a = "some"
    b = "thing\n"
    assert :ok = :gen_tcp.send(socket, a)
    assert :ok = :gen_tcp.send(socket, b)
    assert {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    assert data == a <> b
  end

  @tag :skip
  test "sends back fragmented data 2" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])
    a = "some"
    b = "thi\nng\n"
    assert :ok = :gen_tcp.send(socket, a)
    assert :ok = :gen_tcp.send(socket, b)
    assert {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    assert data == a <> b
  end

  test "works with multiple clients" do
    tasks =
      for id <- 1..5 do
        Task.async(fn ->
          {:ok, socket} = :gen_tcp.connect(~c"localhost", 4000, [:binary, active: false])
          text = "smth_#{id}\n"
          assert :ok = :gen_tcp.send(socket, text)
          assert {:ok, data} = :gen_tcp.recv(socket, 0, 500)
          assert data == text
        end)
      end

    Task.await_many(tasks)
  end
end
