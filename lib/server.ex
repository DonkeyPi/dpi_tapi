defmodule Ash.Term.Server do
  alias Ash.Term.Manager
  alias Ash.Term.Parser
  alias Ash.Term.Driver
  alias Ash.Term.Port
  use Ash.Term.Events

  @title "App Shell"

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
    pid = spawn_link(fn -> run(opts) end)
    {:ok, pid}
  end

  defp run(opts) do
    {delay, opts} = Keyword.pop(opts, :delay, 0)
    if delay > 0, do: :timer.sleep(delay)
    true = Process.register(self(), __MODULE__)
    opts = Keyword.put_new(opts, :title, @title)
    opts = Driver.defaults(opts)

    # pass all opts to port
    port = Port.open(opts)

    # launch manager with trimmed down opts
    cols = Keyword.fetch!(opts, :cols)
    rows = Keyword.fetch!(opts, :rows)

    opts = [
      title: Keyword.get(opts, :title, @title),
      term: Ash.Term.Server.Term,
      driver: Ash.Tui.Driver,
      cols: cols,
      rows: rows,
      hub: self()
    ]

    {:ok, manager} = Manager.start_link(opts)

    loop(%{
      port: port,
      size: {cols, rows},
      selected: manager,
      manager: manager,
      clients: %{},
      count: 0
    })
  end

  defp select(info, %{selected: selected, manager: manager} = state) do
    {cols, rows} = state.size

    case selected do
      ^manager -> send(selected, xon_event(cols, rows))
      _ -> send(selected, {self(), xoff_write()})
    end

    selected = info.client
    send(selected, {self(), xon_write(cols, rows)})
    Map.put(state, :selected, selected)
  end

  defp home(%{selected: selected, manager: manager} = state) do
    {cols, rows} = state.size
    send(selected, {self(), xoff_write()})
    send(manager, xon_event(cols, rows))
    Map.put(state, :selected, manager)
  end

  defp loop(%{port: port, selected: selected, manager: manager} = state) do
    receive do
      {:client, client, title, select} ->
        id = state.count
        ref = Process.monitor(client)
        info = %{id: id, ref: ref, client: client, title: title}
        state = Map.put(state, :count, id + 1)
        state = put_in(state, [:clients, client], info)
        send(manager, model(state))
        state = if select, do: select(info, state), else: state
        loop(state)

      {:DOWN, _, :process, client, _} ->
        {info, state} = pop_in(state, [:clients, client])
        send(manager, model(state))

        state =
          if info.client == selected do
            {cols, rows} = state.size
            send(manager, xon_event(cols, rows))
            Map.put(state, :selected, manager)
          else
            state
          end

        loop(state)

      {:select, ^manager, info} ->
        state =
          case Map.has_key?(state.clients, info.client) and selected == manager do
            true -> select(info, state)
            _ -> state
          end

        loop(state)

      {:input, ^selected, data} ->
        Port.write!(port, data)
        loop(state)

      {:input, _, _data} ->
        # drop data from unselected
        loop(state)

      {^port, {:data, data}} ->
        state =
          case {shortcut(data), selected == manager} do
            {:show, false} ->
              home(state)

            {:show, true} ->
              state

            {:next, true} ->
              case sort(state) do
                [] -> state
                [info | _] -> select(info, state)
              end

            {:next, false} ->
              id = state.clients[selected].id
              next = Enum.find(sort(state), &(&1.id > id))

              case next do
                nil -> home(state)
                _ -> select(next, state)
              end

            {:none, true} ->
              Parser.parse(data, &handle/2, manager)
              state

            {:none, false} ->
              send(selected, {self(), {:write, data}})
              state
          end

        loop(state)

      {^port, {:exit_status, es}} ->
        raise "Port exit status #{es}"

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  defp model(state) do
    {:event, %{type: :model, model: sort(state)}}
  end

  defp sort(state) do
    Enum.sort_by(Map.values(state.clients), & &1.id)
  end

  defp handle(pid, event) do
    send(pid, {:event, event})
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
