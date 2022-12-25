defmodule Ash.Term.Driver do
  @behaviour Ash.Tui.Term
  alias Ash.Term.Encoder
  alias Ash.Term.Parser
  alias Ash.Term.Port
  use Ash.Term.Const

  def start(opts) do
    this = self()
    # keep in sync with defaults in src/init.c
    opts = defaults(opts)
    pid = spawn_link(fn -> run(this, opts) end)
    # opts getting to the app init are desided here.
    # app manager requires hub to be passed this way.
    # used options should be pop at each stage passing
    # along to the app only unused and mandatory opts.
    required = Keyword.take(opts, [:title, :cols, :rows])
    opts = Keyword.drop(opts, Port.opts())
    opts = Keyword.merge(opts, required)
    {pid, opts}
  end

  def defaults(opts) do
    opts
    |> Keyword.put_new(:title, @title)
    |> Keyword.put_new(:cols, @cols)
    |> Keyword.put_new(:rows, @rows)
  end

  def encode(cmd, param), do: Encoder.encode(cmd, param)

  def write(pid, iodata) do
    send(pid, {self(), {:write, iodata}})
    :ok
  end

  defp run(pid, opts) do
    port = Port.open(opts)
    loop(pid, port)
  end

  defp loop(pid, port) do
    receive do
      {^pid, {:write, iodata}} ->
        Port.write!(port, iodata)
        loop(pid, port)

      {^port, {:data, data}} ->
        Parser.parse(data, &handle/3, pid, nil)
        loop(pid, port)

      {^port, {:exit_status, es}} ->
        raise "Port exit status #{es}"

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  defp handle(pid, _, event) do
    send(pid, {:event, event})
  end
end
