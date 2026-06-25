module Trace # <= don't touch this
#==============================================================================
# ? ??-VX ? Trace Stealth System ? version 2.2 ? Prof. Meow Meow
# Converted to VXA by LiTTleDRAgo
#------------------------------------------------------------------------------
# 1.0
# ? Initial release
# 1.1
# ? Alert no longer counts down while a message is displayed
# ? Revised the trace method, slimming it down and fixing the following bugs:
# ? Fixed a bug where tracers' vision would sometimes be blocked by itself
# ? Fixed a bug where tracers would see through Same As Characters events
# 2.0
# ? Added the sound stealth system
# ? Changed the way the trace range is handled
# ? Added ability to disable a tracer's senses
# 2.1
# ? Patched minors bugs
# 2.2
# ? Rewrote trace method using Bresenham's Line Algorithm
#==============================================================================
# ? Tracing With Style - please read everything!
#------------------------------------------------------------------------------
#   Tracer (n): Anything that is searching for the player, e.g., a guard.
#   Designate which events are a tracer by including "tracer" in its name.
#   When a tracer event sees the player, the Alert Switch it turned ON.
#   When the Alert Switch is turned on, a countdown begins. If the player
#   remains out of site for 1800 frames, the Alert Switch is turned OFF.
ALERT_SWITCH = 242        # any game switch
ALERT_COUNTDOWN = 1800  # frames (60 frames is 1 second; 1800 frames is 30 sec)
#==============================================================================
# ? Change How Far Your Guards Can See
#------------------------------------------------------------------------------
#   By default, tracers have an average range of vision: 5 tiles.
#   A tracer's range should be odd: 3, 5, 7, 9, etc.
#   An even value will be the next odd number, e.g., 4 will be a range of 5.
TRACE_RANGE_DEFAULT = 5 # any odd value
#   You can change the range at any time by calling this line:
#    ? $game_map.trace_range = n   where n is the new sight range
#   You may want to change the trace range when the lighting changes:
#    ? For a dark room, or during the night, use 3 or 5.
#    ? For a lit room, or during the day, use 5 or higher.
#==============================================================================
# ? Three Ways To Hide The Player From Sight
#------------------------------------------------------------------------------
#   There are three methods that can be used to hide the player:
#    ? Make the player transparent
#    ? Make the player's opacity to HIDE_OPACITY or lower
#    ? Change the Hide Switch to ON
HIDE_OPACITY = 50      # 0~255 (for realism, keep it low)
HIDE_SWITCH = 243         # any game switch
#==============================================================================
# ? 2.0 Feature ? Making a Ruckus: a guide to sound stealth ?
#------------------------------------------------------------------------------
#   All noises have a loudness value which is it's range. For example, a
#   noise with a loudness of 4 will be heard by all guards within 4 tiles.
#   To make a noise, call the following line from within a Move Route command:
#    ? tss_noise(n)   where n is the range of the noise
#   When a tracer hears a noise, its Caution Self Swith is set ON.
#   To have the tracer move toward the source the sound, call the following
#   line from within it's custom autonomous movement:
#    ? tss_investigate
#   Once the tracer reaches the source, its Caution Self Switch is set OFF.
CAUTION_SELF_SWITCH = "C"         # "A", "B", "C", or "D"
#   When the player sprints, he or she makes some noise!
#   You can change how much noise is made at any time by calling this line:
#    ? $game_player.sprint_noise = n   where n is the range of the noise
DEFAULT_SPRINT_NOISE = 3          # any value (set this to 0 to disable)
#   Here are some example of noises and their estimated range:
#    ? Creaking Floor............ 1~2
#    ? Carefully Closing a Door.. 2~3
#    ? Sneezing or Coughing...... 4~5
#    ? Bumping Into Something.... 4~5
#    ? Tripping Over Furniture... 6~7
#    ? Breaking Glass............ 8~9
#    Sprinting:
#    ? Thief Sprinting........... 2~3
#    ? Civilian Sprinting........ 4~6
#    ? Soldier Sprinting......... 7~9
#    Dialogue:
#    ? Whispering................ 2~3
#    ? Talking................... 4~6
#    ? Shouting.................. 7~9
#==============================================================================
# ? 2.0 Feature ? Two Ways To Disable a Tracer's Senses
#------------------------------------------------------------------------------
#   There are two methods that can be used to disable a tracer's "senses":
#    ? Erase the tracer event
#    ? Change it's Disabling Self Switch to ON
#   Prof tip: "D" is for many things- dead, disabled.... When you knock out a
#   guard, erase or turn it's "D" self switch ON so he can't see or hear you!
ALLOW_SELF_SWITCH_DISABLING = true  # true~false
DISABLING_SELF_SWITCH = "D"         # "A", "B", "C", or "D"
#==============================================================================
# ? Special Effects
#------------------------------------------------------------------------------
#   When a guard sees you, an ! appears above all heads and an ME plays.
SHOW_ALERT = true               # Do you want the ! to display? true~false
PLAY_ALERT = true               # Do you want an ME to play?    true~false
ALERT_ME = "Audio/ME/Shock"     # Which ME do you want to play? any ME
ALERT_VOLUME = 100              # At what volume?               0~100
ALERT_PITCH = 100               # At what pitch?                50~150
#   When the guards call off the search, a ? appears above all heads.
SHOW_QUIT = true                # Do you want the ? to display? true~false
#   2.0 Feature ? When a guards hears a noise, a ? appears above it's head
#   and an ME plays.
SHOW_CAUTION = true             # Do you want the ? to display? true~false
PLAY_CAUTION = true             # Do you want an ME to play?    true~false
CAUTION_ME = "Audio/ME/Mystery" # Which ME do you want to play? any ME
CAUTION_VOLUME = 100            # At what volume?               0~100
CAUTION_PITCH = 100             # At what pitch?                50~150
#==============================================================================
# ? 2.0 Feature ? Something For Fun
#------------------------------------------------------------------------------
#   You can call huh? or hey! through an event script to display '?' or '!'
#   above all active tracer heads!
#==============================================================================
# ? DO NOT TOUCH ANYTHING BELOW THIS POINT - this is for your own safety!   
#==============================================================================
CHECK_INTERVAL = 16  # 16
end
#==============================================================================
# Game System
#==============================================================================
class Game_Map
  #----------------------------------------------------------------------------
  # Local Variables
  #----------------------------------------------------------------------------
  attr_accessor :trace_range
  attr_accessor :alert_countdown
  #----------------------------------------------------------------------------
  # Update
  #----------------------------------------------------------------------------
  alias trace_system_update update unless $@
  def update(*args)
    trace_system_update(*args)
    @trace_range     ||= Trace::TRACE_RANGE_DEFAULT
    @alert_countdown ||= 0
    if @alert_countdown > 0 and !$game_message.visible
      @alert_countdown -= 1
    elsif @alert_countdown <= 0 and $game_switches[Trace::ALERT_SWITCH]
      if Trace::SHOW_QUIT
        for i in $game_map.events.keys
          event = $game_map.events[i]
          if event.name.include?("tracer") and !event.erased
            next if Trace::ALLOW_SELF_SWITCH_DISABLING and
                    event.get_self_switch(Trace::DISABLING_SELF_SWITCH)
            event.balloon_id = 2
          end
        end
      end
      $game_switches[Trace::ALERT_SWITCH] = false
      $game_map.need_refresh = true
    end
  end
end
#==============================================================================
# Game Character
#==============================================================================
class Game_Character
  #----------------------------------------------------------------------------
  # Local Variables
  #----------------------------------------------------------------------------
  attr_accessor :old_x
  attr_accessor :old_y
  attr_accessor :old_player_x
  attr_accessor :old_player_y
  attr_accessor :attention_x
  attr_accessor :attention_y
  #----------------------------------------------------------------------------
  # Initialize
  #----------------------------------------------------------------------------
  alias trace_initialize initialize unless $@
  def initialize
    trace_initialize
    @old_x = @x
    @old_y = @y
    @old_player_x = 0
    @old_player_y = 0
    @attention_x = @x
    @attention_y = @y
  end
  #----------------------------------------------------------------------------
  # Update
  #----------------------------------------------------------------------------
  alias trace_update update unless $@
  def update
    trace_update
    if @id > 0 # if an event
      if name.include?("tracer") and not @erased
        if @old_x != @x or @old_y != @y or
           @old_player_x != $game_player.x or @old_player_y != $game_player.y
          if !$game_switches[Trace::ALERT_SWITCH]
            if tss_trace
              if Trace::PLAY_ALERT
                name = Trace::ALERT_ME
                volume = Trace::ALERT_VOLUME
                pitch = Trace::ALERT_PITCH
                Audio.me_play(name, volume, pitch)
              end
              if Trace::SHOW_ALERT                     
                for event in $game_map.events.values
                  if event.name.include?("tracer") and !event.erased
                    next if Trace::ALLOW_SELF_SWITCH_DISABLING and
                            event.get_self_switch(Trace::DISABLING_SELF_SWITCH)
                    event.balloon_id = 1
                  end
                end
              end
              $game_switches[Trace::ALERT_SWITCH] = true
              $game_map.alert_countdown = Trace::ALERT_COUNTDOWN
              $game_map.need_refresh = true
            end
          end
          @old_x = @x
          @old_y = @y
          @old_player_x = $game_player.x
          @old_player_y = $game_player.y
        end
        if [(@x - @attention_x).abs, (@y - @attention_y).abs].max < 2 and
        get_self_switch(Trace::CAUTION_SELF_SWITCH)
          @balloon_id = 2 if Trace::SHOW_QUIT
          set_self_switch(Trace::CAUTION_SELF_SWITCH, false)
        end
      end
    end
  end 
  #----------------------------------------------------------------------------
  # Trace
  #----------------------------------------------------------------------------
  def tss_trace(range = $game_map.trace_range)
    return false if Trace::ALLOW_SELF_SWITCH_DISABLING and
                    get_self_switch(Trace::DISABLING_SELF_SWITCH)
    return false if $game_player.transparent
    return false if $game_switches[Trace::HIDE_SWITCH]
    return false if $game_player.opacity <= Trace::HIDE_OPACITY
    return false if (range||0) > 0 and !player_in_sight_field?
    x0, y0 = @x * 32 + 16, @y * 32 + 16
    x1, y1 = $game_player.x * 32 + 16, $game_player.y * 32 + 16
    line_points = get_line(x0, y0, x1, y1)
    check_countdown = Trace::CHECK_INTERVAL
    line_points.each do |point|
      if check_countdown > 0
        check_countdown -= 1
      else
        check_countdown = Trace::CHECK_INTERVAL
        x, y = point[:x]/32, point[:y]/32
        break if !$game_player.passable?(x, y, @direction) and !pos?(x, y)
        return true if $game_player.pos?(x, y)
      end
    end
    return false
  end
  #----------------------------------------------------------------------------
  # Player In Sight Field?
  #----------------------------------------------------------------------------
  def player_in_sight_field?   
    # Find the center of the range because the range is radial
    range = 1 + $game_map.trace_range / 2
    # Find the center of the field of vision
    center_vision_x = @x
    center_vision_y = @y
    center_vision_y += range if @direction == 2
    center_vision_x -= range if @direction == 4
    center_vision_x += range if @direction == 6
    center_vision_y -= range if @direction == 8
    # Calculate the X & Y distances between the center of vision and player
    sx = center_vision_x - $game_player.x
    sy = center_vision_y - $game_player.y
    # Return true if the player is within the field of vision
    return true if [sx.abs,sy.abs].max < range
    # Otherwise, return false
    return false
  end
  #----------------------------------------------------------------------------
  # Noise
  #----------------------------------------------------------------------------
  def tss_noise(range = 0)
    if $game_switches[Trace::ALERT_SWITCH] == false
      for event in $game_map.events.values
        if event.name.include?("tracer") and !event.erased
          next if Trace::ALLOW_SELF_SWITCH_DISABLING and
          event.get_self_switch(Trace::DISABLING_SELF_SWITCH)
          sx = event.x - @x
          sy = event.y - @y
          if [sx.abs, sy.abs].max <= range
            if Trace::PLAY_CAUTION
              name = Trace::CAUTION_ME
              volume = Trace::CAUTION_VOLUME
              pitch = Trace::CAUTION_PITCH
              Audio.me_play(name, volume, pitch)
            end
            event.attention_x = @x
            event.attention_y = @y
            event.balloon_id = 2 if Trace::SHOW_CAUTION
            event.set_self_switch(Trace::CAUTION_SELF_SWITCH, true)
          end
        end
      end
    end 
  end
  #--------------------------------------------------------------------------
  # * Investigate
  #--------------------------------------------------------------------------
  def tss_investigate
    sx = @x - @attention_x
    sy = @y - @attention_y
    if sx.abs + sy.abs >= 20
      move_random
    else
      case rand(6)
      when 0..3;  move_toward_position(@attention_x,@attention_y)
      when 4;     move_random
      when 5;     move_forward
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Move Toward Position
  #--------------------------------------------------------------------------
  def move_toward_position(x,y)
    sx = @x - x
    sy = @y - y
    if sx != 0 or sy != 0
      if sx.abs > sy.abs                  # Horizontal distance is longer
        sx > 0 ? move_left : move_right   # Prioritize left-right
        if @move_failed and sy != 0
          sy > 0 ? move_up : move_down
        end
      else                                # Vertical distance is longer
        sy > 0 ? move_up : move_down      # Prioritize up-down
        if @move_failed and sx != 0
          sx > 0 ? move_left : move_right
        end
      end
    end
  end
  #----------------------------------------------------------------------------
  # Get Self Switch
  #----------------------------------------------------------------------------
  def get_self_switch(switch)
    key = [@map_id, @id, switch]
    return $game_self_switches[key]
  end
  #----------------------------------------------------------------------------
  # Set Self Switch
  #----------------------------------------------------------------------------
  def set_self_switch(switch,true_false)
    key = [@map_id, @id, switch]
    $game_self_switches[key] = true_false
    $game_map.need_refresh = true
  end
  #----------------------------------------------------------------------------
  # Get Line
  #----------------------------------------------------------------------------
  # Algorithm by.. Bresenham
  # Written by.... RogueBasin
  #----------------------------------------------------------------------------
  def get_line(x0,y0,x1,y1)
    original_x0, original_y0 = x0, y0
    points = []
    steep = ((y1-y0).abs) > ((x1-x0).abs)
    if steep
      x0,y0 = y0,x0
      x1,y1 = y1,x1
    end
    if x0 > x1
      x0,x1 = x1,x0
      y0,y1 = y1,y0
    end
    deltax = x1-x0
    deltay = (y1-y0).abs
    error = (deltax / 2).to_i
    y = y0
    ystep = nil
    if y0 < y1
      ystep = 1
    else
      ystep = -1
    end
    for x in x0..x1
      if steep
        points << {:x => y, :y => x}
      else
        points << {:x => x, :y => y}
      end
      error -= deltay
      if error < 0
        y += ystep
        error += deltax
      end
    end
    if original_x0 != points[0][:x] or original_y0 != points[0][:y]
      points.reverse!
    end
    return points
  end
end
#==============================================================================
# Game Event
#==============================================================================
class Game_Event < Game_Character
  #----------------------------------------------------------------------------
  # Name (get name)
  #----------------------------------------------------------------------------
  def name
    return @event.name
  end
  #----------------------------------------------------------------------------
  # Erased (get erased)
  #----------------------------------------------------------------------------
  def erased
    return @erased
  end
end
#==============================================================================
# Game Player
#==============================================================================
class Game_Player < Game_Character
  #----------------------------------------------------------------------------
  # Local Variables
  #----------------------------------------------------------------------------
  attr_accessor :old_steps
  attr_accessor :sprint_noise
  #----------------------------------------------------------------------------
  # Update
  #----------------------------------------------------------------------------
  alias trace_player_update update unless $@
  def update(*args)
    trace_player_update(*args)
    @old_steps    ||= 0
    @sprint_noise ||= Trace::DEFAULT_SPRINT_NOISE
    if $game_party.steps > @old_steps + 5 and moving? and dash?
      tss_noise(@sprint_noise)
      @old_steps = $game_party.steps
    end
  end
end
#==============================================================================
# Game Interpreter
#==============================================================================
class Game_Interpreter
  #----------------------------------------------------------------------------
  # Huh?
  #----------------------------------------------------------------------------
  def huh?
    for event in $game_map.events.values
      if event.name.include?("tracer") and !event.erased
        next if Trace::ALLOW_SELF_SWITCH_DISABLING and
        event.get_self_switch(Trace::DISABLING_SELF_SWITCH)
        event.balloon_id = 2 # display ?
      end
    end
  end
  #----------------------------------------------------------------------------
  # Hey!
  #----------------------------------------------------------------------------
  def hey!
    for event in $game_map.events.values
      if event.name.include?("tracer") and !event.erased
        next if Trace::ALLOW_SELF_SWITCH_DISABLING and
        event.get_self_switch(Trace::DISABLING_SELF_SWITCH)
        event.balloon_id = 1 # display !
      end
    end
  end
end
 
class Game_Character
  
  unless method_defined?(:move_upper_right)
    define_method(:move_down)  {|*args| move_straight(2)}
    define_method(:move_left)  {|*args| move_straight(4)}
    define_method(:move_right) {|*args| move_straight(6)}
    define_method(:move_up)    {|*args| move_straight(8)}
    define_method(:move_lower_left)  {|*args| move_diagonal(4, 2)}
    define_method(:move_lower_right) {|*args| move_diagonal(6, 2)}
    define_method(:move_upper_left)  {|*args| move_diagonal(4, 8)}
    define_method(:move_upper_right) {|*args| move_diagonal(6, 8)}
  end
end