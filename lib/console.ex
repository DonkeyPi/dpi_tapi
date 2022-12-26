defmodule Ash.Term.Console do
  @behaviour Ash.Tui.Term
  alias Ash.Term.Encoder
  alias Ash.Term.Client

  @node :ash_console@localhost

  def start(opts) do
    opts = Keyword.put_new(opts, :node, @node)
    Client.start(opts)
  end

  def encode(cmd, param), do: Encoder.encode(cmd, param)

  def write(pid, chardata), do: Client.write(pid, chardata)
end
