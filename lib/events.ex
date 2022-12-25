defmodule Ash.Term.Events do
  # FFFFXX0000000000
  # FF -> sys
  # FF61 -> print
  # FF13 -> pause
  # 00 -> flags
  # 0000 -> x
  # 0000 -> y
  defmacro __using__(_) do
    quote do
      import Ash.Term.Events
    end
  end

  def xon_event(cols, rows) when cols in 0..0xFFFF and rows in 0..0xFFFF do
    {:event, %{type: :sys, key: :print, flag: :none, x: cols, y: rows}}
  end

  def xon_write(cols, rows), do: {:write, xon_packet(cols, rows)}

  def xon_packet(cols, rows) when cols in 0..0xFFFF and rows in 0..0xFFFF do
    "FFFF6100#{hex(cols, 4)}#{hex(rows, 4)}"
  end

  def xoff_event(), do: {:event, %{type: :sys, key: :pause, flag: :none}}

  def xoff_write(), do: {:write, xoff_packet()}

  def xoff_packet() do
    "FFFF130000000000"
  end

  defp hex(v, p), do: Integer.to_string(v, 16) |> String.pad_leading(p, "0")
end
