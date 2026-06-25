#------------------------------------------------------------------------------#
#  Galv's Keypad Input
#------------------------------------------------------------------------------#
#  For: RPGMAKER VX ACE
#  Version 1.1
#------------------------------------------------------------------------------#
#  2012-10-15 - Version 1.1 - Allows for a larger max number to show in the box
#  2012-10-5 - Version 1.0 - release
#------------------------------------------------------------------------------#
#  The keypad is just a fancy version of the 'Number Input' event command.
#  When "OK" is pressed, it outputs the entered number to the chosen variable.
#  When "X" is pressed, it outputs -1 to the chosen variable (for eventing).
#
#  From then on, it's up to your eventing skills what to do with the number.
#  Call the keypad with the script call:
#------------------------------------------------------------------------------#
#  keypad_input
#------------------------------------------------------------------------------#
 
$imported = {} if $imported.nil?
$imported["Keypad"] = true
 
module Keypad
 
#------------------------------------------------------------------------------#
#  SCRIPT SETUP OPTIONS
#------------------------------------------------------------------------------#
 
  KEYPAD_VAR = 1              # Variable that the keypad stores number in.
  MAX_NUM = 4               # Amount of numbers you can enter in the keypad.
   
  OK_SE = ["Heal7", 80, 150]  # OK sound effect. ["SE Name", volume, pitch]
   
#------------------------------------------------------------------------------#
#  SCRIPT SETUP OPTIONS
#------------------------------------------------------------------------------#
 
end
 
class Scene_Keypad < Scene_MenuBase
 
  def start
    super
    @number = ""
    @edit_window = Window_Numpad.new(@number, @max_char)
    @input_window = Window_NumInput.new(@edit_window)
    @input_window.set_handler(:confirm, method(:on_input_ok))
    @input_window.set_handler(:leave, method(:on_input_x))
    @input_window.activate
  end
  def on_input_ok
    $game_variables[Keypad::KEYPAD_VAR] = @edit_window.numeral.to_i
    SceneManager.return
  end
  def on_input_x
    $game_variables[Keypad::KEYPAD_VAR] = -1
    SceneManager.return
  end
 
end
 
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
# * New Window - Numpad Number Output
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
 
class Window_Numpad < Window_Base
 
  attr_reader   :numeral                  # number amount
  attr_reader   :index                    # cursor position
  attr_reader   :max_char                 # maximum number of numbers
 
  def initialize(number, max_char)
    x = ((Graphics.width - 185) / 2) - (extend_size * 0.5)
    y = (Graphics.height - (fitting_height(4) + fitting_height(9) + 8)) / 2
    super(x, y, 185 + extend_size, fitting_height(1))
    @max_char = Keypad::MAX_NUM
    @numeral = number.to_s[0, @max_char]
    @index = @numeral.size
    refresh
  end
   
  def extend_size
    if Keypad::MAX_NUM > 10
      20 * (Keypad::MAX_NUM - 10)
    else
      0
    end
  end
 
  def add(ch)
    return false if @index >= @max_char
    @numeral += ch
    @index += 1
    refresh
    return true
  end
 
  def back
    return on_name_x if @index == 0
    @index -= 1
    @numeral = @numeral[0, @index]
    refresh
    return true
  end
   
  def on_name_x
    $game_variables[Keypad::KEYPAD_VAR] = -1
    SceneManager.return
  end 
 
  def char_width
    text_size("0").width + 5
  end
 
  def left
    numeral_center = (contents_width) / 2
    numeral_width = (@max_char) * char_width
    return [numeral_center - numeral_width / 2, contents_width - numeral_width].min
  end
 
  def item_rect(index)
    Rect.new(left + index * char_width, -3, char_width, line_height)
  end
 
  def draw_char(index)
    contents.font.size = 28
    rect = item_rect(index)
    rect.x -= 1
    rect.width += 4
    change_color(normal_color)
    draw_text(rect, @numeral[index] || "")
  end
 
  def refresh
    contents.clear
    @numeral.size.times {|i| draw_char(i) }
  end
   
   
end
 
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
# * New Window - Numpad Input
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
 
class Window_NumInput < Window_Selectable
 
  NUMPAD = [ '1','2','3','4','5', '6','7','8','9','OK', '0', 'X']
 
  def initialize(edit_window)
    super((Graphics.width - 185) / 2, edit_window.y + edit_window.height + 8,
          185, fitting_height(9))
    @edit_window = edit_window
    @index = 0
    refresh
    update_cursor
  end
 
  def character
    if @index == 10
      NUMPAD[@index]
    elsif @index < 9 
      NUMPAD[@index]
    else
      ""
    end
  end
 
  def is_x?
    @index == 11
  end
 
  def is_ok?
    @index == 9
  end
 
  def item_rect(index)
    contents.font.size = 32
    rect = Rect.new
    rect.x = index % 3 * 32 + index % 3 / 1 * 16
    rect.y = index / 3 * line_height * 2
    rect.width = 62
    rect.height = 62
    rect
  end
 
  def refresh
    contents.clear
    change_color(normal_color)
    12.times {|i| draw_text(item_rect(i), NUMPAD[i], 1) }
  end
 
  def update_cursor
    cursor_rect.set(item_rect(@index))
  end
 
  def cursor_movable?
    active
  end
 
  def cursor_down(wrap)
    if @index < 9 or wrap
      @index = (index + 3) % 12
    end
  end
 
  def cursor_up(wrap)
    if @index > 2 or wrap
      @index = (index - 3) % 12
    end
  end
   
  def cursor_right(wrap)
    if @index % 12 < 11
      @index += 1
    elsif wrap
      @index -= 11
    end
  end
 
  def cursor_left(wrap)
    if @index % 12 > 0
      @index -= 1
    elsif wrap
      @index += 11
    end
  end
 
  def process_cursor_move
    super
    update_cursor
  end
 
  def process_handling
    return unless open? && active
    process_back if Input.repeat?(:B)
    process_ok   if Input.trigger?(:C)
  end
 
  def process_back
    Sound.play_cancel if @edit_window.back
  end
 
  def process_ok
    if !character.empty?
      on_name_add
    elsif is_x?
      Sound.play_cancel
      call_handler(:leave)
    elsif is_ok?
      RPG::SE.new(Keypad::OK_SE[0], Keypad::OK_SE[1], Keypad::OK_SE[2]).play
      call_handler(:confirm)
    end
  end
 
  def on_name_add
    if @edit_window.add(character)
      Sound.play_ok
    else
      Sound.play_buzzer
    end
  end
 
end
 
class Game_Interpreter
  def keypad_input
    SceneManager.call(Scene_Keypad)
    wait(1)
  end
end