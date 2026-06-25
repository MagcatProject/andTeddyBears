#------------------------------------------------------------------------------#
#  Galv's Random Loot
#------------------------------------------------------------------------------#
#  For: RPGMAKER VX ACE
#  Version 1.1
#------------------------------------------------------------------------------#
#  2014-01-07 - Version 1.1 - bugfixes & updates by Malagar (aka Fhizban)
#  2012-09-29 - Version 1.0 - release
#------------------------------------------------------------------------------#
#  This script allows you to have a script call to gain random loot from chests.
#  Add notetags to items to specify level requirements and rarity values.
#  A notetag can also be added to items that you want to increase the chance to
#  find rarer loot.
#------------------------------------------------------------------------------#
#  Instructions:
#  Notetag ITEMS, ARMORS and WEAPONS that you want to random with the following:
#  (If items do not have these tags, they will not appear in a random chest.)
#------------------------------------------------------------------------------#
#
#  <family: x>                    # The group or family the item belongs to
#  <rarity: x>                    # The rarity value (higher is rarer)
#  <level-min: x>                 # Min level of player for item to show
#  <level-max: x>                 # Max level of player for item to show
#
#------------------------------------------------------------------------------#
#  Option notetag for ARMORS and WEAPONS
#------------------------------------------------------------------------------#
#
#  <lucky: x>                     # All equipped lucky items are added to
#                                 # the chance to get rarer items.
#
#------------------------------------------------------------------------------#
#  Using this script call, you can randomly obtain an item:
#  random_item(family, type, min rareness, max rareness, monster-in-a-box)
#------------------------------------------------------------------------------#
#  EXAMPLE:
#
#  random_item(1, 1, 1, 15, 0)
#
#------------------------------------------------------------------------------#
#  family can be any integer (number) or 0.
#  0 = drops any item of the stated type
#  x = drops only items of the stated type that share the family you have stated.
#      the item family is a integer number (1, 20, 500 etc.). If you add families
#      to your items notetags, you can set the random_item to spawn treasure only
#      of the stated family.
#
#  type can be 1: item, 2: armor, 3: weapons, 4: any
#
#  min rarness and max rareness determine the item rarity that the script
#  call will successfully obtain.
#  eg. min rareness = 10 and max rareness is 50, then that script call will
#  generate a number between 10 and 50. An item can be obtained only if it has
#  rarity EQUAL to or LESS THAN the number generated.
#
#  monster-in-a-box troop is used to decide what TROOP ID appears if you are
#  unlucky enough to random it.
#------------------------------------------------------------------------------#
#  This method works better if items/weapons/armors are organised with common 
#  at the top and rarer items further down in their database lists.
#------------------------------------------------------------------------------#
 
$imported = {} if $imported.nil?
$imported["Random_Loot"] = true
 
module Random_Loot
 
#------------------------------------------------------------------------------#
#  SCRIPT SETUP OPTIONS
#------------------------------------------------------------------------------#
 
  GET_MESSAGE = "Найдено "              # Text before item name.
  GET_MESSAGE_AFTER = "!"             # Text after item name.
 
  FAIL_MESSAGE = "В коробке ничего нет."        # Text when random item comes up nothing.
   
  SOUND_EFFECT = ["Chime2", 90, 100]    # Sound effect of gaining an item.
                                      # ["SE Name", volume, pitch]
                                      # Make "SE Name" = "" for no sound.
   
  MONSTER_CHANCE = 0                 # % chance that if no item is found, a
                                      # battle will happen instead.
  ESCAPE_MONSTER = true               # Can you escape it? true or false
   
  MONSTER_MESSAGE = "В коробке монстр!"     # Message when a monster appears.
                                             # Make it "" to disable.
 
#------------------------------------------------------------------------------#
#  END SCRIPT SETUP OPTIONS
#------------------------------------------------------------------------------#
 
end
 
module Random_Loot_Notetags
  def loot_rarity
    if @loot_rarity.nil?
      if @note =~ /<rarity: (.*)>/i
        @loot_rarity = $1.to_i
      else
        @loot_rarity = 0
      end
    end
    @loot_rarity
  end
  def loot_level_min
    if @loot_level_min.nil?
      if @note =~ /<level-min: (.*)>/i
        @loot_level_min = $1.to_i
      else
        @loot_level_min = 0
      end
    end
    @loot_level_min
  end
  def loot_level_max
    if @loot_level_max.nil?
      if @note =~ /<level-max: (.*)>/i
        @loot_level_max = $1.to_i
      else
        @loot_level_max = 0
      end
    end
    @loot_level_max
  end
  def loot_lucky
    if @loot_lucky.nil?
      if @note =~ /<lucky: (.*)>/i
        @loot_lucky = $1.to_i
      else
        @loot_lucky = 0
      end
    end
    @loot_lucky
  end
  def loot_family
    if @loot_family.nil?
      if @note =~ /<family: (.*)>/i
        @loot_family = $1.to_i
      else
        @loot_family = 0
      end
    end
    @loot_family
  end
  end # Random_Loot_Notetags
 
class RPG::Item
  include Random_Loot_Notetags
end
class RPG::Armor
  include Random_Loot_Notetags
end
class RPG::Weapon
  include Random_Loot_Notetags
end
 
class Game_Interpreter
 
  def random_item(family, type, rarity_min, rarity_max, monster_id)
    if type >= 4
      type = rand(3) + 1
    end
    if type == 1
      @loot = $data_items
    elsif type == 2
      @loot = $data_armors
    else
      @loot = $data_weapons
    end
 
    mem = 0
    eqs = 0
    luck_bonus = 0
    
    #no_equips = ($game_party.members.count) * ($game_party.members[0].equips.count)
    #no_equips.times { |i|
    #    if $game_party.members[mem].equips[eqs] != nil
    #      luck_bonus += $game_party.members[mem].equips[eqs].loot_lucky
    #    end
    #    if eqs < 5
    #      eqs += 1
    #    else
    #      eqs = 1
    #      mem += 1
    #    end
    #}
     
    no_items = @loot.count - 1
    rare_chance = rand(rarity_max - rarity_min) + rarity_min + luck_bonus + 1
    checked = 0
    random_item = rand(no_items) + 1
    restart = false
    begin_count = rand(no_items) + 1
     
    no_items.times { |i|
      i = i + random_item
      begin_count += 1 if restart
      if i > no_items
        i = i - i + rand(no_items) + 1
        restart = true
      end
       
      if @loot[i].loot_level_max >= $game_party.leader.level && @loot[i].loot_level_min <= $game_party.leader.level
        if @loot[i].loot_family == family or family == 0
          if @loot[i].loot_rarity <= rare_chance
            if rand(1) <= 0
              $game_party.gain_item(@loot[i], 1)
              RPG::SE.new(Random_Loot::SOUND_EFFECT[0], Random_Loot::SOUND_EFFECT[1], Random_Loot::SOUND_EFFECT[2]).play
              $game_message.add(Random_Loot::GET_MESSAGE + "\\I[" + @loot[i].icon_index.to_s + "]" + @loot[i].name.to_s + Random_Loot::GET_MESSAGE_AFTER)
              wait_for_message
              return
            end
          end
        end
      end
      checked += 1
 
      if checked == no_items
        monster_chance = rand(100) + 1
        if monster_chance <= Random_Loot::MONSTER_CHANCE
          if Random_Loot::MONSTER_MESSAGE != ""
            $game_message.add("\\>" + Random_Loot::MONSTER_MESSAGE + "\\.\\.\\.\\^")
            wait_for_message
          end
          BattleManager.setup(monster_id, Random_Loot::ESCAPE_MONSTER, false)
          SceneManager.call(Scene_Battle)
        else
          $game_message.add(Random_Loot::FAIL_MESSAGE)
          wait_for_message
        end
      end
    }
  end
   
end # Game_Interpreter