#-------------------------------------------------------------------------------
#  Galv's Event Pop-Ups
#-------------------------------------------------------------------------------
#  For: RPGMAKER VX ACE
#  Version 1.1
#------------------------------------------------------------------------------#
#  2013-03-03 - Version 1.1 - crash fix
#  2013-02-24 - Version 1.1 - release
#------------------------------------------------------------------------------#
#  Just another pop up script, nothing special here other than I made it (which
#  could be less special! haha). Manually create a text pop up or automatically 
#  whenever you give the player an item via event command - pops up the item's
#  icon above their head with amount gained.
#------------------------------------------------------------------------------#
#  SCRIPT CALL to manually call the pop up
#------------------------------------------------------------------------------#
#
#  popup(target,type,id,amount)
#  
#
#  # target = event id you want popup to appear on. 0 is for player
#  # type = :item, :armor, :weapon or "Other Text"
#  # id = the item, armor or weapon id OR icon id if using "Other Text"
#  # amount = how many of item you wish to display are being gained or lost
#
#------------------------------------------------------------------------------#
#  EXAMPLES:
#  popup(0," Skulls",1,5)  # '5 x Skulls' with icon 1 above player
#  popup(2,"Hello  ",0,0)  # 'Hello' with no icon above event 2
#  popup(4,:item,1,-10)    # -10 Potions (with icon) above event 4
#
#  NOTE: The Gain item, weapon, armor and gold event commands automatically pop
#        up with the item gained/lost. Only one pop up can be active at a time.
#------------------------------------------------------------------------------#
 
($imported ||= {})["Galv_Map_Popups"] = true
module Galv_Mpop
 
#------------------------------------------------------------------------------#  
#  SETUP OPTIONS
#------------------------------------------------------------------------------#
 
  DISABLE_SWITCH = 106  # Turn swith ON to disable this.
   
   
  SE_GAIN = ["Chime2",100,100]   # "SE_Name",volume,pitch when gaining item
  SE_LOSE = ["Miss",100,100]    # "SE_Name",volume,pitch when losing item
   
  # These sounds only play with the add or remove items event command. Custom
  # item pop up won't display a sound so you can play your own.
 
 
  Y_OFFSET = -75                # Y offset for popup text
   
  CURRENCY_ICON  = 361          # Icon that appears when gaining/losing money
   
  FONT = "Coder's Crux"                # Font used for pop ups
  GAIN_COLOR = [255,255,255]    # RGB colour for gaining item text
  LOSE_COLOR = [255,200,200]    # RGB colour for losing item text
   
#------------------------------------------------------------------------------#  
#  END SETUP OPTIONS
#------------------------------------------------------------------------------#
 
end
 
 
class Game_Map
  alias galv_map_pop_gp_initialize initialize
  def initialize
    galv_map_pop_gp_initialize
  end
   
  alias galv_map_pop_gp_update update
  def update(main = false)
    update_popup if @popsprite
    galv_map_pop_gp_update(main)
  end
   
  def update_popup
    @popsprite.update
  end
   
  def dispose_popup
    @popsprite.dispose if @popsprite
    @popsprite = nil
  end
   
  def popup(target,item_type,item_id,amount)
    @popsprite.dispose if @popsprite
    character = get_ptarget(target)
    item = get_pitem(item_type,item_id)
    @popsprite = Sprite_PopText.new(@viewport1,character,item,amount)
  end
   
  def get_ptarget(target)
    if target == 0; return $game_player
    elsif target > 0; return $game_map.events[target]
    end
  end
   
  def get_pitem(item_type,item_id)
    case item_type
    when :item;   $data_items[item_id]
    when :weapon; $data_weapons[item_id]
    when :armor;  $data_armors[item_id]
    else; [item_type.to_s,item_id]
    end
  end
   
end # Game_Player < Game_Character
 
 
class Scene_Map < Scene_Base
  def dispose_spriteset
    @spriteset.dispose
    $game_map.dispose_popup
  end
end
 
class Sprite_PopText < Sprite
  def initialize(viewport,target,item,amount)
    super(viewport)
    @character = target
    @item = item
    @rise = 0
    @rise_speed = 15
    @amount = amount
    create_bitmap
    update
  end
 
  def dispose
    self.bitmap.dispose
    if @icon_sprite
      @icon_sprite.bitmap.dispose
      @icon_sprite.dispose
    end
    super
  end
 
  def create_bitmap
    if @item
      @icon_sprite = Sprite.new
      @icon_sprite.bitmap = Cache.system("Iconset")
    end
    @x_offset = -92
    self.bitmap = Bitmap.new(200, 20)
    self.bitmap.font.size = 20
    self.bitmap.font.name = Galv_Mpop::FONT
    self.bitmap.font.shadow = 20
    self.bitmap.font.bold = true
    if @amount >= 0
      self.bitmap.font.color.set(
      Galv_Mpop::GAIN_COLOR[0],Galv_Mpop::GAIN_COLOR[1],Galv_Mpop::GAIN_COLOR[2])
    else
      self.bitmap.font.color.set(
      Galv_Mpop::LOSE_COLOR[0],Galv_Mpop::LOSE_COLOR[1],Galv_Mpop::LOSE_COLOR[2])
    end
    self.z = 2
  end
 
  def update
    super
    update_position
    update_bitmap
    update_visibility
    update_icon if @icon_sprite
    end_popup
  end
 
  def end_popup
    return $game_map.dispose_popup if @rise >= 280
  end
 
  def name_text
    if @item.is_a?(Array)
      amount = @amount > 1 || @amount < -1 ? @amount.to_s : ""
      return amount + @item[0].to_s
    elsif @item
      amount = @amount != 0 ? @amount.to_s : ""
      return @amount >= 1 ? "x" + amount : amount
    else
      return ""
    end
  end
   
  def update_bitmap
    @rise += 1
    self.bitmap.clear
    self.bitmap.draw_text(self.bitmap.rect, name_text, 1)
    if @item && @item.is_a?(Array)
      self.draw_icon(@item[1])
    elsif @item
      self.draw_icon(@item.icon_index)
    end
  end
   
  def draw_icon(icon_index)
    rect = Rect.new(icon_index % 16 * 24, icon_index / 16 * 24, 24, 24)
    @icon_sprite.src_rect = rect
    @icon = icon_index
  end
   
  def calculate_y
    if @rise_speed > 0
      @rise_speed -= 1
      return -(@rise * @rise_speed * 0.2)
    else
      return 0
    end
  end
 
  def update_position
    self.x = @character.screen_x + @x_offset
    if @amount >= 0
      self.y = @character.screen_y + Galv_Mpop::Y_OFFSET + calculate_y
    else
      self.y = @character.screen_y + Galv_Mpop::Y_OFFSET - 10 + @rise * 0.2
    end
  end
 
  def update_icon
    @icon_sprite.x = @character.screen_x - name_text.length * 4 - 20
    @icon_sprite.y = self.y - 2
    @icon_sprite.opacity = self.opacity
  end
   
  def update_visibility
    self.opacity = 500 + (name_text.length * 20) - @rise * 6
  end
end # Sprite_PopText < Sprite
 
 
class Game_Interpreter
   
  def psound(amount)
    if amount > 0
      RPG::SE.new(Galv_Mpop::SE_GAIN[0],Galv_Mpop::SE_GAIN[1],Galv_Mpop::SE_GAIN[2]).play
    elsif amount < 0
      RPG::SE.new(Galv_Mpop::SE_LOSE[0],Galv_Mpop::SE_LOSE[1],Galv_Mpop::SE_LOSE[2]).play
    end
  end
   
  alias galv_map_pop_gi_command_125 command_125
  def command_125
    difference = $game_party.gold
    galv_map_pop_gi_command_125
    amount = $game_party.gold - difference
    return if amount == 0 || $game_switches[Galv_Mpop::DISABLE_SWITCH]
    psound(amount)
    $game_map.popup(0,"",Galv_Mpop::CURRENCY_ICON,amount)
  end
 
  alias galv_map_pop_gi_command_126 command_126
  def command_126
    difference = $game_party.item_number($data_items[@params[0]])
    galv_map_pop_gi_command_126
    amount = $game_party.item_number($data_items[@params[0]]) - difference
    return if amount == 0 || $game_switches[Galv_Mpop::DISABLE_SWITCH]
    psound(amount)
    $game_map.popup(0,:item,@params[0],amount)
  end
   
  alias galv_map_pop_gi_command_127 command_127
  def command_127
    difference = $game_party.item_number($data_weapons[@params[0]])
    galv_map_pop_gi_command_127
    amount = $game_party.item_number($data_weapons[@params[0]]) - difference
    return if amount == 0 || $game_switches[Galv_Mpop::DISABLE_SWITCH]
    psound(amount)
    $game_map.popup(0,:weapon,@params[0],amount)
  end
   
  alias galv_map_pop_gi_command_128 command_128
  def command_128
    difference = $game_party.item_number($data_armors[@params[0]])
    galv_map_pop_gi_command_128
    amount = $game_party.item_number($data_armors[@params[0]]) - difference
    return if amount == 0 || $game_switches[Galv_Mpop::DISABLE_SWITCH]
    psound(amount)
    $game_map.popup(0,:armor,@params[0],amount)
  end
   
  def popup(target,item_type,item_id,amount)
    $game_map.popup(target,item_type,item_id,amount)
  end
end # Game_Interpreter