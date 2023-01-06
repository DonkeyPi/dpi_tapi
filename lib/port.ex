defmodule Dpi.Term.Port do
  @opts [
    :title,
    :rows,
    :cols,
    :width,
    :height,
    :motion,
    :pointer
  ]

  def opts(), do: @opts

  def open(opts) do
    args =
      for {key, value} <- Keyword.take(opts, @opts) do
        "--#{key}=#{encode(value)}"
      end

    opts = [:binary, :exit_status, :stream, args: args]
    priv = :code.priv_dir(:dpi_term)
    target = File.read!("#{priv}/target") |> String.trim()
    Port.open({:spawn_executable, '#{priv}/#{target}/dpi_term'}, opts)
  end

  def write!(port, iodata) do
    true = Port.command(port, iodata)
  end

  def close(port) do
    Port.close(port)
  end

  defp encode(true), do: 1
  defp encode(false), do: 0
  defp encode(other), do: other
end
