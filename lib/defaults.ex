defmodule Ash.Term.Defaults do
  defmacro __using__(_) do
    quote do
      # keep in sync with defaults in src/init.c
      @cols 100
      @rows 30
      @title "Ash.Term"
    end
  end
end
