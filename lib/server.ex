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
    pid = spawn_link(fn -> hub_start(opts) end)
    {:ok, pid}
  end

  defp hub_start(opts) do
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
      {:client, client, title} ->
        id = state.count
        ref = Process.monitor(client)
        info = %{id: id, ref: ref, client: client, title: title}
        state = Map.put(state, :count, id + 1)
        state = put_in(state, [:clients, client], info)
        send(manager, model(state))
        hub_loop(state)

      {:DOWN, _, :process, client, _} ->
        {info, state} = pop_in(state, [:clients, client])
        send(manager, model(state))

        state =
          if info.client == selected do
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
              selected = info.client
              send(selected, {self(), xon_write(cols, rows)})
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
              send(selected, {self(), xoff_write()})
              send(manager, xon_event(cols, rows))
              Map.put(state, :selected, manager)

            {true, true} ->
              state

            {false, true} ->
              Parser.parse(data, &handle/3, manager, nil)
              state

            {false, false} ->
              send(selected, {self(), {:write, data}})
              state
          end

        hub_loop(state)

      {^port, {:exit_status, es}} ->
        raise "Port exit status #{es}"

      msg ->
        raise "Unexpected #{inspect(msg)}"
    end
  end

  # control + esc
  # kubuntu opens app manager as well and its the press event
  # 11->PRESS 12->RELEASE (using both because of above)
  # ff1b->ESC
  # 01->Shift flags
  # 02->Control flags
  # 00000000->xy missing data
  defp shortcut(""), do: false
  defp shortcut("11ff1b02" <> <<_::binary-size(8)>> <> _), do: true
  defp shortcut("12ff1b02" <> <<_::binary-size(8)>> <> _), do: true
  defp shortcut("11ff1b01" <> <<_::binary-size(8)>> <> _), do: true
  defp shortcut("12ff1b01" <> <<_::binary-size(8)>> <> _), do: true
  defp shortcut(<<_::binary-size(16)>> <> tail), do: shortcut(tail)

  defp model(state) do
    list = Enum.sort_by(Map.values(state.clients), & &1.id)
    {:event, %{type: :model, model: list}}
  end

  defp handle(pid, _, event) do
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
