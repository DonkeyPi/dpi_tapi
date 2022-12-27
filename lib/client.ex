defmodule Ash.Term.Client do
  @behaviour Ash.Tui.Term
  alias Ash.Term.Encoder
  alias Ash.Term.Parser

  @state %{pid: nil, active: false, cols: 0, rows: 0}

  def start(opts) do
    this = self()
    title = Keyword.fetch!(opts, :title)
    {server, opts} = Keyword.pop(opts, :server, Ash.Term.Server)
    {select, opts} = Keyword.pop(opts, :select, false)
    {node, opts} = Keyword.pop(opts, :node)

    server =
      case node do
        nil -> Process.whereis(server)
        node -> :rpc.call(node, Process, :whereis, [server])
      end

    pid = spawn_link(fn -> run(this, server, title, select) end)

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

  defp run(pid, server, title, select) do
    Process.monitor(server)
    send(server, {:client, self(), title, select})
    loop(pid, server, %{@state | pid: pid})
  end

  defp loop(pid, server, %{active: false} = state) do
    receive do
      {^pid, {:write, _iodata}} ->
        # drop data
        loop(pid, server, state)

      {^server, {:write, data}} ->
        # wait xon
        state = Parser.parse(data, &handle/2, state)
        loop(pid, server, state)

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  defp loop(pid, server, %{active: true} = state) do
    receive do
      {^pid, {:write, iodata}} ->
        send(server, {:input, self(), iodata})
        loop(pid, server, state)

      {^server, {:write, data}} ->
        state = Parser.parse(data, &handle/2, state)
        loop(pid, server, state)

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
