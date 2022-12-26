defmodule Ash.Term.Socket.Server do
  alias Ash.Term.Manager
  alias Ash.Term.Parser
  alias Ash.Term.Driver
  alias Ash.Term.Port
  use Ash.Term.Events

  @port 8023
  @toms 2000
  @title "App Shell"

  # Moving to an rpc strategy to ensure message atomicity.
  # No matter the flush strategy, there is always a chance that
  # an utf8 codepoint gets partially transmitted an that i-n words
  # wont correctly complete it.
  @flush String.duplicate("i", 260)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      restart: :permanent,
      type: :worker,
      shutdown: 500
    }
  end

  def start_link(opts \\ []) do
    pid = spawn_link(fn -> server_setup(opts) end)
    {:ok, pid}
  end

  defp server_setup(opts) do
    {port, opts} = Keyword.pop(opts, :port, @port)
    hub = spawn_link(fn -> hub_start(opts) end)
    opts = [:binary, packet: :raw, reuseaddr: true]
    {:ok, socket} = :gen_tcp.listen(port, opts)
    accept_loop(socket, hub)
  end

  defp accept_loop(socket, hub) do
    {:ok, client} = :gen_tcp.accept(socket)
    pid = spawn(fn -> client_setup(client, hub) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    accept_loop(socket, hub)
  end

  defp hub_start(opts) do
    opts = Keyword.put_new(opts, :title, @title)
    opts = Driver.defaults(opts)

    # pass all opts to port
    port = Port.open(opts)

    # launch manager with trimmed down opts
    cols = Keyword.fetch!(opts, :cols)
    rows = Keyword.fetch!(opts, :rows)

    opts = [
      title: Keyword.get(opts, :title, @title),
      term: Ash.Term.Socket.Server.Term,
      driver: Ash.Tui.Driver,
      cols: cols,
      rows: rows,
      hub: self()
    ]

    {:ok, manager} = Manager.start_link(opts)

    hub_loop(%{
      port: port,
      size: {cols, rows},
      selected: manager,
      manager: manager,
      clients: %{},
      count: 0
    })
  end

  defp hub_loop(%{port: port, selected: selected, manager: manager, size: {cols, rows}} = state) do
    receive do
      {:open, client, info} ->
        id = state.count
        info = Map.put(info, :id, id)
        state = Map.put(state, :count, id + 1)
        state = put_in(state, [:clients, client], info)
        send(manager, model(state))
        hub_loop(state)

      {:close, client} ->
        {info, state} = pop_in(state, [:clients, client])
        send(manager, model(state))

        state =
          if info.pid == selected do
            Port.write!(port, @flush)
            send(manager, xon_event(cols, rows))
            Map.put(state, :selected, manager)
          else
            state
          end

        hub_loop(state)

      {:select, ^manager, info} ->
        state =
          case Map.has_key?(state.clients, info.client) and selected == manager do
            true ->
              selected = info.pid
              Port.write!(port, @flush)
              send(selected, xon_write(cols, rows))
              Map.put(state, :selected, selected)

            _ ->
              state
          end

        hub_loop(state)

      {:input, ^selected, data} ->
        Port.write!(port, data)
        hub_loop(state)

      {:input, _, _data} ->
        # drop data from unselected
        hub_loop(state)

      {^port, {:data, data}} ->
        state =
          case {shortcut(data), selected == manager} do
            {true, false} ->
              Port.write!(port, @flush)
              send(selected, xoff_write())
              send(manager, xon_event(cols, rows))
              Map.put(state, :selected, manager)

            {true, true} ->
              state

            {false, true} ->
              Parser.parse(data, &handle/3, manager, nil)
              state

            {false, false} ->
              send(selected, {:write, data})
              state
          end

        hub_loop(state)

      {^port, {:exit_status, es}} ->
        raise "Port exit status #{es}"

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  defp model(state) do
    list = Enum.sort_by(Map.values(state.clients), & &1.id)
    {:event, %{type: :model, model: list}}
  end

  defp handle(pid, _, event) do
    send(pid, {:event, event})
  end

  defp client_setup(client, hub) do
    Process.monitor(hub)
    {:ok, {{a, b, c, d}, p}} = :inet.peername(client)
    peer = "#{a}.#{b}.#{c}.#{d}:#{p}"

    receive do
      {:tcp, ^client, title} ->
        info = %{client: client, pid: self(), peer: peer, title: title}
        send(hub, {:open, client, info})
        client_loop(client, hub)

      {:tcp_closed, ^client} ->
        {:client, :closed}

      {:DOWN, _, :process, ^hub, reason} ->
        {:hub, reason}

      msg ->
        raise "Unexpected #{inspect(msg)}"
    after
      @toms -> :drop
    end
  end

  defp client_loop(client, hub) do
    receive do
      {:write, data} ->
        :ok = :gen_tcp.send(client, data)
        client_loop(client, hub)

      {:tcp, ^client, data} ->
        send(hub, {:input, self(), data})
        client_loop(client, hub)

      {:tcp_closed, ^client} ->
        send(hub, {:close, client})
        {:client, :closed}

      {:DOWN, _, :process, ^hub, reason} ->
        {:hub, reason}

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  # Term driver for the manager application
  defmodule Term do
    @behaviour Ash.Tui.Term
    alias Ash.Term.Encoder

    def start(opts), do: {Keyword.fetch!(opts, :hub), opts}
    def encode(cmd, param), do: Encoder.encode(cmd, param)

    def write(hub, chardata) do
      send(hub, {:input, self(), chardata})
      :ok
    end
  end
end
