defmodule Ash.Term.Socket.Client do
  @behaviour Ash.Tui.Term
  alias Ash.Term.Encoder
  alias Ash.Term.Parser

  @port 8023

  @state %{pid: nil, active: false, cols: 0, rows: 0}

  def start(opts) do
    this = self()
    title = Keyword.fetch!(opts, :title)
    host = Keyword.get(opts, :host, "127.0.0.1")
    port = Keyword.get(opts, :port, @port)
    pid = spawn_link(fn -> run(this, host, port, title) end)

    {cols, rows} =
      receive do
        {:event, %{type: :sys, key: :print, x: cols, y: rows}} -> {cols, rows}
      end

    send(pid, {self(), {:write, encode(:clear, nil)}})
    opts = Keyword.put(opts, :cols, cols)
    opts = Keyword.put(opts, :rows, rows)
    {pid, opts}
  end

  def encode(cmd, param), do: Encoder.encode(cmd, param)

  def write(pid, chardata) do
    send(pid, {self(), {:write, chardata}})
    :ok
  end

  defp run(pid, host, port, title) do
    host = String.to_charlist(host)

    opts = [:binary, packet: :raw, active: true]
    {:ok, socket} = :gen_tcp.connect(host, port, opts)
    :ok = :gen_tcp.send(socket, title)
    loop(pid, socket, %{@state | pid: pid})
  end

  defp loop(pid, socket, %{active: false} = state) do
    receive do
      {^pid, {:write, _iodata}} ->
        # drop data
        loop(pid, socket, state)

      {:tcp, ^socket, data} ->
        # wait xon
        state = Parser.parse(data, &handle/2, state)
        loop(pid, socket, state)

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  defp loop(pid, socket, %{active: true} = state) do
    receive do
      {^pid, {:write, iodata}} ->
        :ok = :gen_tcp.send(socket, iodata)
        loop(pid, socket, state)

      {:tcp, ^socket, data} ->
        state = Parser.parse(data, &handle/2, state)
        loop(pid, socket, state)

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  defp handle(state, event) do
    state =
      case event do
        %{type: :sys, key: :pause} ->
          %{state | active: false}

        %{type: :sys, key: :print, x: cols, y: rows} ->
          %{state | active: true, cols: cols, rows: rows}

        _ ->
          state
      end

    if state.active, do: send(state.pid, {:event, event})
    state
  end
end
