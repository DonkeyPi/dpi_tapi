defmodule Dpi.Term.Const do
  defmacro __using__(_) do
    quote do
      use Bitwise

      @dpi_key_release 0x10 ||| 0x01
      @dpi_key_press 0x10 ||| 0x02
      @dpi_button_release 0x20 ||| 0x01
      @dpi_button_press 0x20 ||| 0x02
      @dpi_2button_press 0x20 ||| 0x04
      @dpi_pointer_motion 0x60 ||| 0x01
      @dpi_scroll_up 0xA0 ||| 0x01
      @dpi_scroll_down 0xA0 ||| 0x02
      # term server internal comm
      @dpi_sys_req 0xFF

      @dpi_shift_mask 1
      @dpi_control_mask 2
      @dpi_alt_mask 4
      @dpi_super_mask 8

      @dpi_mouse_left 0x0001
      @dpi_mouse_right 0x0002
      @dpi_mouse_middle 0x0003

      @dpi_key_escape 0xFF1B
      @dpi_key_f1 0xFFBE
      @dpi_key_f2 0xFFBF
      @dpi_key_f3 0xFFC0
      @dpi_key_f4 0xFFC1
      @dpi_key_f5 0xFFC2
      @dpi_key_f6 0xFFC3
      @dpi_key_f7 0xFFC4
      @dpi_key_f8 0xFFC5
      @dpi_key_f9 0xFFC6
      @dpi_key_f10 0xFFC7
      @dpi_key_f11 0xFFC8
      @dpi_key_f12 0xFFC9

      @dpi_key_backspace 0xFF08

      @dpi_key_tab 0xFF09

      @dpi_key_return 0xFF0D

      @dpi_key_print 0xFF61
      @dpi_key_pause 0xFF13

      @dpi_key_insert 0xFF63
      @dpi_key_home 0xFF50
      @dpi_key_page_up 0xFF55

      @dpi_key_delete 0xFFFF
      @dpi_key_end 0xFF57
      @dpi_key_page_down 0xFF56

      @dpi_key_left 0xFF51
      @dpi_key_up 0xFF52
      @dpi_key_right 0xFF53
      @dpi_key_down 0xFF54

      @keyrange 32..126

      # latam spanish
      @dpi_key_notsign 0x0AC
      @dpi_key_degree 0x0B0
      @dpi_key_exclamdown 0x0A1
      @dpi_key_questiondown 0x0BF

      @dpi_key_ntilde 0x0F1
      @dpi_key_Ntilde 0x0D1

      @dpi_key_udiaeresis 0x0FC
      @dpi_key_Udiaeresis 0x0DC

      @dpi_key_aacute 0x0E1
      @dpi_key_eacute 0x0E9
      @dpi_key_iacute 0x0ED
      @dpi_key_oacute 0x0F3
      @dpi_key_uacute 0x0FA

      @dpi_key_Aacute 0x0C1
      @dpi_key_Eacute 0x0C9
      @dpi_key_Iacute 0x0CD
      @dpi_key_Oacute 0x0D3
      @dpi_key_Uacute 0x0DA

      @keymap %{
        @dpi_mouse_left => :bleft,
        @dpi_mouse_right => :bright,
        @dpi_mouse_middle => :bmiddle,
        @dpi_key_escape => :esc,
        @dpi_key_f1 => :f1,
        @dpi_key_f2 => :f2,
        @dpi_key_f3 => :f3,
        @dpi_key_f4 => :f4,
        @dpi_key_f5 => :f5,
        @dpi_key_f6 => :f6,
        @dpi_key_f7 => :f7,
        @dpi_key_f8 => :f8,
        @dpi_key_f9 => :f9,
        @dpi_key_f10 => :f10,
        @dpi_key_f11 => :f11,
        @dpi_key_f12 => :f12,
        @dpi_key_backspace => :backspace,
        @dpi_key_tab => :tab,
        @dpi_key_return => :return,
        @dpi_key_print => :print,
        @dpi_key_pause => :pause,
        @dpi_key_insert => :insert,
        @dpi_key_home => :home,
        @dpi_key_page_up => :pup,
        @dpi_key_delete => :delete,
        @dpi_key_end => :end,
        @dpi_key_page_down => :pdown,
        @dpi_key_left => :kleft,
        @dpi_key_up => :kup,
        @dpi_key_right => :kright,
        @dpi_key_down => :kdown,

        # latam spanish
        @dpi_key_notsign => '¬',
        @dpi_key_degree => '°',
        @dpi_key_exclamdown => '¡',
        @dpi_key_questiondown => '¿',
        @dpi_key_ntilde => 'ñ',
        @dpi_key_Ntilde => 'Ñ',
        @dpi_key_udiaeresis => 'ü',
        @dpi_key_Udiaeresis => 'Ü',
        @dpi_key_aacute => 'á',
        @dpi_key_eacute => 'é',
        @dpi_key_iacute => 'í',
        @dpi_key_oacute => 'ó',
        @dpi_key_uacute => 'ú',
        @dpi_key_Aacute => 'Á',
        @dpi_key_Eacute => 'É',
        @dpi_key_Iacute => 'Í',
        @dpi_key_Oacute => 'Ó',
        @dpi_key_Uacute => 'Ú'
      }
    end
  end
end
