#------------------------------------------------------------------------------#
#  Galv's Visibility Range
#------------------------------------------------------------------------------#
#  For: RPGMAKER VX ACE
#  Version 1.1
#------------------------------------------------------------------------------#
#  2014-02-11 - Version 1.1 - added z level setting
#  2013-05-31 - Version 1.0 - release
#------------------------------------------------------------------------------#
#  This script can make the player only able to see in a certain radius around
#  themself. The rest is darkness. This size and opacity of this darkness is
#  controlled using variables and turned on/off using a switch.
#
#  Put this script below Materials and above main.
#  Requires an image that can be found in the demo on galvs-scripts.com. Images
#  for this script go in your /Graphics/System folder.
#------------------------------------------------------------------------------#
 
#------------------------------------------------------------------------------#
#  SCRIPT CALL
#------------------------------------------------------------------------------#
#  visimage("ImageName")       # Can change the image used
#------------------------------------------------------------------------------#
 
 
($imported ||= {})["Galv_Vis_Range"] = true
module Galv_Vis
 
#------------------------------------------------------------------------------#
#  SETTINGS - Don't forget to set these to unused variables and switch!
#------------------------------------------------------------------------------#
 
  SWITCH = 77      # This switch turns the visibility range on/off. Default OFF
 
  SIZEVAR = 10     # This variable controls how far player can see. Default 100
 
  OPACITYVAR = 11  # This variable controls the darkness opacity.   Default 255
   
   
  Z_LEVEL = 0      # Make this higher or lower to change the z level
                   # (to make it appear above or below other stuff)
 
#------------------------------------------------------------------------------#
#  END SETTINGS
#------------------------------------------------------------------------------#
 
end # Galv_Vis
 
 
class Spriteset_Map
  alias galv_vis_sm_initialize initialize
  def initialize
    create_visrange if $game_switches[Galv_Vis::SWITCH]
    galv_vis_sm_initialize
  end
   
  def create_visrange
    @visrange = Sprite.new
    @visrange.bitmap = Cache.system($game_system.visimage)
    @visrange.ox = @visrange.bitmap.width / 2
    @visrange.oy = @visrange.bitmap.height / 2
    @visrange.z = Galv_Vis::Z_LEVEL
  end
   
  alias galv_vis_sm_update update
  def update
    galv_vis_sm_update
    update_visrange
  end
   
  def update_visrange
    if $game_switches[Galv_Vis::SWITCH]
      create_visrange if !@visrange
      @visrange.x = $game_player.screen_x
      @visrange.y = $game_player.screen_y - 16
      @visrange.opacity = $game_variables[Galv_Vis::OPACITYVAR]
      zoom = [$game_variables[Galv_Vis::SIZEVAR].to_f * 0.01,0.5].max
      @visrange.zoom_x = zoom
      @visrange.zoom_y = zoom
    else
      dispose_visrange
    end
  end
   
  alias galv_vis_sm_dispose dispose
  def dispose
    galv_vis_sm_dispose
    dispose_visrange
  end
   
  def dispose_visrange
    return if !@visrange
    @visrange.bitmap.dispose
    @visrange.dispose
    @visrange = nil
  end
end # Spriteset_Map
 
 
module DataManager
  class << self
    alias galv_vis_dm_setup_new_game setup_new_game
  end
   
  def self.setup_new_game
    galv_vis_dm_setup_new_game
    $game_system.init_visvars
  end
end # DataManager
 
 
class Scene_Map
  attr_accessor :spriteset
end
 
class Game_System
  attr_accessor :visimage
 
  def init_visvars
    @visimage = "VisRange"
    $game_variables[Galv_Vis::OPACITYVAR] = 255
    $game_variables[Galv_Vis::SIZEVAR] = 70
  end
end
 
 
class Game_Interpreter
  def visimage(img)
    $game_system.visimage = img
    SceneManager.scene.spriteset.dispose_visrange
  end
end