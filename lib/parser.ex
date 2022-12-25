defmodule Ash.Term.Parser do
  use Ash.Term.Const

  def parse("", _, _, state), do: state

  def parse(
        <<packet::binary-size(16)>> <> data,
        callback,
        pid,
        state
      ) do
    event = parse_packet(packet)

    state =
      case event do
        nil -> state
        _ -> callback.(pid, state, event)
      end

    parse(data, callback, pid, state)
  end

  def parse_packet(packet) do
    <<
      type::binary-size(2),
      key::binary-size(4),
      flags::binary-size(2),
      x::binary-size(4),
      y::binary-size(4)
    >> = packet

    type = String.to_integer(type, 16)
    flags = String.to_integer(flags, 16)
    key = String.to_integer(key, 16)
    x = String.to_integer(x, 16)
    y = String.to_integer(y, 16)

    event = %{x: x, y: y}

    event = Map.put(event, :shift, (flags &&& @ash_shift_mask) > 0)
    event = Map.put(event, :control, (flags &&& @ash_control_mask) > 0)
    event = Map.put(event, :alt, (flags &&& @ash_alt_mask) > 0)
    event = Map.put(event, :super, (flags &&& @ash_super_mask) > 0)

    event =
      case flags do
        0 -> event |> Map.put(:flag, :none)
        @ash_control_mask -> event |> Map.put(:flag, :control)
        @ash_shift_mask -> event |> Map.put(:flag, :shift)
        @ash_alt_mask -> event |> Map.put(:flag, :alt)
        @ash_super_mask -> event |> Map.put(:flag, :super)
        _ -> event |> Map.put(:flag, :mix)
      end

    event =
      case type do
        @ash_sys_req ->
          event
          |> Map.put(:type, :sys)

        @ash_key_release ->
          event
          |> Map.put(:type, :key)
          |> Map.put(:action, :release)

        @ash_key_press ->
          event
          |> Map.put(:type, :key)
          |> Map.put(:action, :press)

        @ash_button_release ->
          event
          |> Map.put(:type, :mouse)
          |> Map.put(:action, :release)

        @ash_button_press ->
          event
          |> Map.put(:type, :mouse)
          |> Map.put(:action, :press)

        @ash_2button_press ->
          event
          |> Map.put(:type, :mouse)
          |> Map.put(:action, :press2)

        @ash_pointer_motion ->
          event
          |> Map.put(:type, :mouse)
          |> Map.put(:action, :move)

        @ash_scroll_up ->
          event
          |> Map.put(:type, :mouse)
          |> Map.put(:action, :scroll)
          |> Map.put(:dir, :up)

        @ash_scroll_down ->
          event
          |> Map.put(:type, :mouse)
          |> Map.put(:action, :scroll)
          |> Map.put(:dir, :down)
      end

    cond do
      key in @keyrange -> event |> Map.put(:key, [key])
      Map.has_key?(@keymap, key) -> event |> Map.put(:key, @keymap[key])
      event[:type] == :key -> nil
      true -> event
    end
  end
end
