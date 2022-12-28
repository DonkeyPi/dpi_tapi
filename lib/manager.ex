defmodule Ash.Term.Manager do
  use Ash.React, app: true
  use Ash.Tui

  @log false

  def init(opts) do
    set_handler(&handler/1)
    if @log, do: log("Opts #{inspect(opts)}")
    {&main/1, opts}
  end

  defp handler(%{type: :model, model: model}) do
    put_prop(:model, model)
    if @log, do: log("Model #{inspect(model)}")
  end

  defp handler(event) do
    if @log, do: log("Event #{inspect(event)}")
  end

  defp main(%{cols: cols, rows: rows, hub: hub}) do
    model = get_prop(:model, [])
    {selected, set_selected} = use_state(:selected, -1)
    # integer `selected` to resolve info in last moment
    # because select equality uses {index, item} but cannot
    # detect other changes beyond that.
    map = for {info, i} <- Enum.with_index(model), into: %{}, do: {i, info}
    items = for info <- model, do: info.title

    panel :main, size: {cols, rows} do
      # label is transparent in default theme
      # use default background
      label(:title,
        scale: 2,
        size: {cols, 2},
        text: "Applications",
        class: %{fore: @ash_logo_fore, back: get_style(:back, nil, nil)}
      )

      label(:shortcut,
        origin: {0, 2},
        size: {cols, 1},
        text: "(ctrl+esc)",
        class: %{fore: @ash_logo_fore, back: get_style(:back, nil, nil)}
      )

      button(:button,
        origin: {cols - 10, 0},
        size: {10, 3},
        text: "Select",
        border: :round,
        enabled: selected >= 0,
        on_click: fn -> send(hub, {:select, self(), Map.get(map, selected)}) end
      )

      select(:select,
        origin: {0, 3},
        size: {cols, rows - 4},
        items: items,
        on_change: fn {i, _} -> set_selected.(i) end
      )

      label(:logo,
        text: "ash>",
        origin: {0, rows - 1},
        size: {div(cols, 2), 2},
        align: :left,
        class: %{fore: @ash_logo_fore, back: get_style(:back, nil, nil)}
      )

      label(:url,
        origin: {div(cols, 2), rows - 1},
        size: {div(cols, 2), 2},
        text: "appshell.org",
        align: :right,
        class: %{fore: @ash_logo_fore, back: get_style(:back, nil, nil)}
      )
    end
  end
end
