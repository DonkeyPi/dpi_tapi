defmodule Dpi.Term.Encoder do
  use Bitwise

  def encode(:clear, _), do: "c"
  def encode(:hide, _), do: "h"
  def encode(:show, _), do: "s"
  def encode(:font, n) when n in 0x00..0xFF, do: "n#{hex(n, 2)}"
  def encode(:fore, c) when c in 0x00..0xFF, do: "f#{hex(c, 2)}"
  def encode(:back, c) when c in 0x00..0xFF, do: "b#{hex(c, 2)}"

  def encode(:fore, c) when c in 0x100..0xFFFFFF,
    do: encode(:fore, {c >>> 16 &&& 0xFF, c >>> 8 &&& 0xFF, c &&& 0xFF})

  def encode(:back, c) when c in 0x100..0xFFFFFF,
    do: encode(:back, {c >>> 16 &&& 0xFF, c >>> 8 &&& 0xFF, c &&& 0xFF})

  def encode(:fore, {r, g, b}) when r in 0..0xFF and g in 0..255 and b in 0..255,
    do: "F#{hex(r, 2)}#{hex(g, 2)}#{hex(b, 2)}"

  def encode(:back, {r, g, b}) when r in 0..0xFF and g in 0..255 and b in 0..255,
    do: "B#{hex(r, 2)}#{hex(g, 2)}#{hex(b, 2)}"

  def encode(:scale, {s, x, y}) when s in 1..16 and x in 0..15 and y in 0..15,
    do: "e#{hex(s - 1, 2)}#{hex(x, 2)}#{hex(y, 2)}"

  def encode(:x, x) when x in 0x00..0xFF, do: "x#{hex(x, 2)}"
  def encode(:x, x) when x in 0x100..0xFFFF, do: "X#{hex(x, 4)}"
  def encode(:y, y) when y in 0x00..0xFF, do: "y#{hex(y, 2)}"
  def encode(:y, y) when y in 0x100..0xFFFF, do: "Y#{hex(y, 4)}"
  def encode(:move, {x, y}), do: [encode(:x, x), encode(:y, y)]
  def encode(:motion, _), do: "m"

  def encode(:layout, n) when n in 0x00..0xFF, do: "k#{hex(n, 2)}"

  def encode(:title, title) when byte_size(title) < 256,
    do: ["t", hex(byte_size(title), 2), title]

  # ensure the 0xff chunks are codepoint complete
  # block -> 'a' | 'abc' | {'a', n}
  def encode(:text, block) do
    acc = encode_text(block, 0, [], [])
    # strip unneeded wrapping list
    case acc |> Enum.reverse() do
      [acc] -> acc
      acc -> acc
    end
  end

  defp encode_text({d, n}, _, _, acc) when n > 0 do
    str = to_string([d])
    len = byte_size(str)
    nn = min(255, n)
    cmd = ["r", hex(nn, 2), hex(len, 2), str]
    encode_text({d, n - nn}, 0, [], [cmd | acc])
  end

  defp encode_text({_d, _n}, _, _, acc), do: acc
  defp encode_text([], 0, [], acc), do: acc

  defp encode_text([], count, chunk, acc) when count > 0 do
    chunk = Enum.reverse(chunk) |> to_string()
    cmd = ["w", hex(count, 2), chunk]
    encode_text([], 0, [], [cmd | acc])
  end

  defp encode_text([d | dd], count, chunk, acc) do
    str = to_string([d])
    len = byte_size(str)

    if count + len > 255 do
      chunk = Enum.reverse(chunk) |> to_string()
      cmd = ["w", hex(count, 2), chunk]
      encode_text([d | dd], 0, [], [cmd | acc])
    else
      encode_text(dd, count + len, [d | chunk], acc)
    end
  end

  defp hex(v, p),
    do: Integer.to_string(v, 16) |> String.pad_leading(p, "0")
end
