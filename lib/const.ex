defmodule Ash.Term.Const do
  defmacro __using__(_) do
    quote do
      use Bitwise

      @ash_key_release 0x10 ||| 0x01
      @ash_key_press 0x10 ||| 0x02
      @ash_button_release 0x20 ||| 0x01
      @ash_button_press 0x20 ||| 0x02
      @ash_2button_press 0x20 ||| 0x04
      @ash_pointer_motion 0x60 ||| 0x01
      @ash_scroll_up 0xA0 ||| 0x01
      @ash_scroll_down 0xA0 ||| 0x02
      # term server internal comm
      @ash_sys_req 0xFF

      @ash_shift_mask 1
      @ash_control_mask 2
      @ash_alt_mask 4
      @ash_super_mask 8

      @ash_mouse_left 0x0001
      @ash_mouse_right 0x0002
      @ash_mouse_middle 0x0003

      @ash_key_escape 0xFF1B
      @ash_key_f1 0xFFBE
      @ash_key_f2 0xFFBF
      @ash_key_f3 0xFFC0
      @ash_key_f4 0xFFC1
      @ash_key_f5 0xFFC2
      @ash_key_f6 0xFFC3
      @ash_key_f7 0xFFC4
      @ash_key_f8 0xFFC5
      @ash_key_f9 0xFFC6
      @ash_key_f10 0xFFC7
      @ash_key_f11 0xFFC8
      @ash_key_f12 0xFFC9

      @ash_key_backspace 0xFF08

      @ash_key_tab 0xFF09

      @ash_key_return 0xFF0D

      @ash_key_print 0xFF61
      @ash_key_pause 0xFF13

      @ash_key_insert 0xFF63
      @ash_key_home 0xFF50
      @ash_key_page_up 0xFF55

      @ash_key_delete 0xFFFF
      @ash_key_end 0xFF57
      @ash_key_page_down 0xFF56

      @ash_key_left 0xFF51
      @ash_key_up 0xFF52
      @ash_key_right 0xFF53
      @ash_key_down 0xFF54

      @keyrange 32..126

      # latam spanish
      @ash_key_notsign 0x0AC
      @ash_key_degree 0x0B0
      @ash_key_exclamdown 0x0A1
      @ash_key_questiondown 0x0BF

      @ash_key_ntilde 0x0F1
      @ash_key_Ntilde 0x0D1

      @ash_key_udiaeresis 0x0FC
      @ash_key_Udiaeresis 0x0DC

      @ash_key_aacute 0x0E1
      @ash_key_eacute 0x0E9
      @ash_key_iacute 0x0ED
      @ash_key_oacute 0x0F3
      @ash_key_uacute 0x0FA

      @ash_key_Aacute 0x0C1
      @ash_key_Eacute 0x0C9
      @ash_key_Iacute 0x0CD
      @ash_key_Oacute 0x0D3
      @ash_key_Uacute 0x0DA

      @keymap %{
        @ash_mouse_left => :bleft,
        @ash_mouse_right => :bright,
        @ash_mouse_middle => :bmiddle,
        @ash_key_escape => :esc,
        @ash_key_f1 => :f1,
        @ash_key_f2 => :f2,
        @ash_key_f3 => :f3,
        @ash_key_f4 => :f4,
        @ash_key_f5 => :f5,
        @ash_key_f6 => :f6,
        @ash_key_f7 => :f7,
        @ash_key_f8 => :f8,
        @ash_key_f9 => :f9,
        @ash_key_f10 => :f10,
        @ash_key_f11 => :f11,
        @ash_key_f12 => :f12,
        @ash_key_backspace => :backspace,
        @ash_key_tab => :tab,
        @ash_key_return => :return,
        @ash_key_print => :print,
        @ash_key_pause => :pause,
        @ash_key_insert => :insert,
        @ash_key_home => :home,
        @ash_key_page_up => :pup,
        @ash_key_delete => :delete,
        @ash_key_end => :end,
        @ash_key_page_down => :pdown,
        @ash_key_left => :kleft,
        @ash_key_up => :kup,
        @ash_key_right => :kright,
        @ash_key_down => :kdown,

        # latam spanish
        @ash_key_notsign => '¬',
        @ash_key_degree => '°',
        @ash_key_exclamdown => '¡',
        @ash_key_questiondown => '¿',
        @ash_key_ntilde => 'ñ',
        @ash_key_Ntilde => 'Ñ',
        @ash_key_udiaeresis => 'ü',
        @ash_key_Udiaeresis => 'Ü',
        @ash_key_aacute => 'á',
        @ash_key_eacute => 'é',
        @ash_key_iacute => 'í',
        @ash_key_oacute => 'ó',
        @ash_key_uacute => 'ú',
        @ash_key_Aacute => 'Á',
        @ash_key_Eacute => 'É',
        @ash_key_Iacute => 'Í',
        @ash_key_Oacute => 'Ó',
        @ash_key_Uacute => 'Ú'
      }
    end
  end
end
