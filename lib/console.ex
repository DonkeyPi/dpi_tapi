defmodule Dpi.Term.Console do
  @behaviour Dpi.Tui.Term
  alias Dpi.Term.Encoder
  alias Dpi.Term.Client

  @node :dpi_console@localhost

  def start(opts) do
    opts = Keyword.put_new(opts, :node, @node)
    Client.start(opts)
  end

  def encode(cmd, param), do: Encoder.encode(cmd, param)

  def write(pid, chardata), do: Client.write(pid, chardata)
end
