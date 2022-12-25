defmodule Ash.EncoderTest do
  use ExUnit.Case
  alias Ash.Term.Encoder

  defp text(block) do
    Encoder.encode(:text, block) |> to_string()
  end

  defp fore(color) do
    Encoder.encode(:fore, color) |> to_string()
  end

  defp back(color) do
    Encoder.encode(:back, color) |> to_string()
  end

  defp title(title) do
    Encoder.encode(:title, title) |> to_string()
  end

  test "text encoder test" do
    assert "f00" = fore(0)
    assert "fFF" = fore(255)
    assert "F000100" = fore(256)
    assert "F123456" = fore(0x123456)
    assert "F654321" = fore(0x654321)
    assert "FFFFFFF" = fore(0xFFFFFF)
    assert "b00" = back(0)
    assert "bFF" = back(255)
    assert "B000100" = back(256)
    assert "B123456" = back(0x123456)
    assert "B654321" = back(0x654321)
    assert "BFFFFFF" = back(0xFFFFFF)
    assert "w01a" == text('a')
    assert "w03abc" == text('abc')
    assert "w03─" == text('─')
    assert "w04a─" == text('a─')
    assert "rFF01a" == text({'a', 255})
    assert "rFF01ar0101a" == text({'a', 256})
    assert "rFF03─" == text({'─', 255})
    assert "rFF03─r0103─" == text({'─', 256})
    long = List.duplicate(?a, 100) ++ List.duplicate(?b, 155)
    assert "wFF#{long}" == text(long)
    assert "wFF#{long}w01c" == text(long ++ [?c])
    assert "tFF#{long}" == title("#{long}")
  end
end
