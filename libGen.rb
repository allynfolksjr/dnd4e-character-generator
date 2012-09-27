#!/usr/bin/env ruby
=begin

To do-

  # Oh no! One of your characters died. Did you want to remove them forever, or drag their corpse around?
  # Switch characters
  # Actual interactive CLI until you stop messing around with them.
  # List methods that characters can do.
  # More classes/races [all races added, still need to add classes
  # mechanism to list and select characters to use actively
  # ...
  # Discover fusion power
  # Mine the moon for Helium-3  
=end

require 'colored'

# These are the master list of available classes and races.
# Whenever adding a new one of either type be sure to add it here as well.
AVAILABLE_CLASSES = %w(Fighter Wizard)
AVAILABLE_RACES = %w(Dragonborn Dwarf Eladrin Elf HalfElf Halfling Human Tiefling)

# Master array to hold all the character objects generated
$characters = []
$you = nil

##
# Standardize method of displaying text to user.
#
# Requires the "colored" gem for proper use. Note that for #bold, it will
# automatically add an extra linebreak at the end.

module Say
  extend self
  # Outputs text with bold formatting. Good for headers and important information.
  def bold(text)
    puts "\n#{text}".bold
  end
  # Outputs normal text with linebreaks.
  def text(text)
    puts "\n#{text}\n"
  end
  # Outputs red and bold text with a (!). Good for alerts and errors.
  def negative(text)
    puts "\n(!) #{text}".red.bold
  end
  # Outputs blue and bold text with a -->. Good for getting the user to do something.
  def command(text)
    puts "\n--> #{text}".blue.bold
  end
  # Outputs in green and bold. Good for a victory!
  def positive(text)
    puts "\n#{text}".green.bold
  end
  # Outputs arrays in an easier to read format.
  def array(array)
    puts "\n"
    array.each_with_index do |value,index|
      puts "#{index+1}. #{value.to_s}".yellow
    end
    puts "\n"
  end
  # This should spit out a plain-er array.
  def array_no_index(array)
    puts "\n"
    array.each do |value|
      puts "#{value.to_s}".yellow
    end
    puts "\n"
  end
  def get
    gets.chomp
  end
  def get_with_array(array)
    Say.array(array)
    Say.command "Type Choice"
    result = gets.chomp.capitalize
    if result.to_i != 0
      if result.to_i > array.count || result.to_i < 1
        Say.negative "Your choice is out of the range."
        get_with_array(array)
      else
        return array[result.to_i-1]
      end
    end
    return result
  end
  def clear
    system("clear")
  end
  def enter_continue
    Say.command "Press [Enter] to continue."
    gets
  end
end


module Simulator
  extend self
  def greet
    Say.bold "DnD 4e Character Generator"
    Say.text "Nikky Southerland | nikky.southerland@gmail.com"
  end
  def menu
    Say.clear
    Say.bold "\tMain Menu"
    Say.text "1. Go Questing"
    Say.text "2. Switch Character"
    Say.text "3. Create Character"
    Say.text "4. Level Up"
    Say.text "5. Display All Characters"
    Say.text "6. Display Your Character"
    Say.text "7. Exit"
    Say.command "Type number of choice"
    choice = Say.get.to_i
    if choice > 7 || choice < 1
      Say.negative "That is not a valid choice."
      Say.enter_continue
      menu
    end
    case choice
    when 1
      Say.negative "Not possible yet"
      Say.enter_continue
      menu
    when 2
      Character.select_character
      menu
    when 3
      race_choice = Character.select_race
      class_choice = Character.select_class
      $you = Character.construct_character(race_choice,class_choice)
      Say.enter_continue
      menu
    when 4
      Say.negative "Not possible yet"
      menu
    when 5
      if $you.nil?
        Say.negative "No character defined yet"
        Say.enter_continue
        menu
      end
      Character.list_characters
      Say.enter_continue
      menu
    when 6
      if $you.nil?
        Say.negative "No character defined yet"
        Say.enter_continue
        menu
      end
      $you.display
      Say.enter_continue
      menu
    when 7
      exit
    end
  end
end





##
# Standardize dice rolling simulation
#
# With no arguments, it will roll a 1d6 once. Otherwise, you can specify different behaviour.
#
# Examples:
# Dice.roll(20,8,2) --> Roll 8d20 and drop the lowest 2.
# Dice.roll(6,6,2,1) --> Roll 6d6, drop the lowest 1, and show the raw rolls.

module Dice
  extend self
  # by default it'll roll 1d6
  def roll(sides=6,times=1,drop_lowest=0,raw=nil)
    if drop_lowest >= times
      Say.negative "You're trying to drop #{drop_lowest} dice, but are only rolling #{times} time" + ( times == 1 ?  "" : "s" ) + "!"
      return 0
    end
    i = 0
    result = []
    while i < times
      result << rand(sides)+1
      i += 1
    end
    # Following line for debug, will remove later
    Say.text "Here are my raw rolls: #{result}, and I dropped #{drop_lowest} of them" unless raw.nil?
    # I don't really need to use return here, but I do it anyway
    return result.sort.drop(drop_lowest).inject(:+)
  end
end

##
# The scaffold will just get you started with picking your race and class
# and then inits your new user as the "you" object
# Eventually these should be merged into the main Character class as class methods




##
# Character classes defined as modules should go here.
#
# Fighter, etc. etc.

module Fighter
  def load_initial_class_variables
    @p_class = "Fighter"
    @weapon = "pickaxe"
    def load_class_modifiers
    end
  end
end

module Wizard
  def load_initial_class_variables
    @p_class = "Wizard"
    @weapon = "Staff of Justice"
  end
  def load_class_modifiers
  end
end


##
# Stock character class

class Character
  include Say
  attr_accessor :weapon, :p_class, :race, :core_stats, :calculated_stats, :character_unique_traits
  def initialize
    @core_stats = {
      str: 0,
      con: 0,
      dex: 0,
      int: 0,
      wis: 0,
      cha: 0
    }
    @calculated_stats = {
      hp: 0,
      bloodied_value: 0
    }

    @character_unique_traits = {
      first_name: nil,
      last_name: nil,
      honorific: nil,
      sex: nil
    }
    #generate_random_stats
    load_initial_class_variables
    load_initial_race_variables
    stat_generation
    generate_sex
    generate_name
    load_class_modifiers
    load_race_modifiers
  end

  # Display name, class, race, and the core stats of a character.
  def display
    Say.bold "#{@character_unique_traits[:first_name]} #{@character_unique_traits[:last_name]}, a mighty #{@character_unique_traits[:sex]} #{@race} #{@p_class}."
    @core_stats.each do |trait, score|
      next if trait == :racial_traits_applied
      puts ("#{trait.upcase}: #{score}" +  (score >= 17  ? " (!)" : " ")).blue
    end
    Say.text "Weapon: #{@weapon}"
  end


  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end

  def stat_generation
    Say.bold "Stats Generation Module"
    Say.text "There are two options: rolling your stats randomly, and using the standard stats."
    Say.text "Additionally, after your stats are rolled, you can choose to apply them randomly, or selectively to each trait."
    Say.command "Type 'r' to roll random stats, or 's' for the standard DnD 4e stats"
    choice = Say.get
    if choice.downcase == "r"
      generate_random_stats
    elsif choice.downcase == "s"
      generate_normal_stats
    else
      Say.negative "Invalid choice. Try again"
      begin_stat_generation
      # assign_stats
    end
  end

  def assign_stats
    # things to allow you to assign stats manually goes here
  end

  def generate_normal_stats
    @non_assign_stat_grid = [10,11,14,14,15,16]
    apply_stats
  end

  # Generate the core six stats using the normal approach.
  # Eventually there should be an option to have you just do all random, or roll random and then feed into the regular stat selector
  def generate_random_stats
    @non_assign_stat_grid = []
    6.times do
      @non_assign_stat_grid << Dice.roll(6,4,1)
    end
    apply_stats
    #@core_stats.each { |k,v| @core_stats[k] = Dice.roll(6,4,1) }
  end

  def apply_stats
    Say.positive "Your initial stats have been rolled!"
    Say.text "\tRaw Rolls: #{@non_assign_stat_grid}\n\tSorted: #{@non_assign_stat_grid.sort}"
    # Say.text "Average: #{@non_assign_stat_grid.inject {sum,n} sum + n / @non_assign_stat_grid.size}"
    Say.bold "Do you want to have these randomly assigned to traits, or do you want to select?"
    Say.command "Enter 'r' for random, or 's' for select"
    choice = Say.get
    if choice.downcase == "r"
      @core_stats.each_with_index do |(k,v) , i|
        @core_stats[k] = @non_assign_stat_grid[i]
      end
    elsif choice.downcase == "s"
      Say.bold "Statistic Assigner Module"
      Say.text "Here are your rolls: #{@non_assign_stat_grid.sort}. For each value, type in which you want to use."
      @core_stats.each do |k,v|
        Say.command "Enter in value for #{k}. Possible choices are: #{@non_assign_stat_grid.sort}"
        selection = Say.get.to_i
        if @non_assign_stat_grid.include?(selection)
          @core_stats[k] = selection
          @non_assign_stat_grid.delete_at(@non_assign_stat_grid.index(selection))
          next
        else
          Say.negative "Not a valid choice"
          redo
        end
      end
    else
      Say.negative "Invalid choice. Try again"
      begin_stat_generation
    end
    Say.positive "Your stats are:"
    Say.array(@core_stats)
  end





  # Generate sexy times. I mean. Character sex.
  def generate_sex
    rand(2) == 0 ? @character_unique_traits[:sex] = "male" : @character_unique_traits[:sex] = "female"
  end
  # Load some default names if none other are specified.
  #
  # To-do: Honorific support based on level.
  def generate_name
    @male_first_names ||= %w(Buzz James John Fred Neil)
    @female_first_names ||= %w(Valentina Svetlana Sally)
    @last_names ||= %w(Baggins Bell Armstrong Aldrin Collins Grissom Chaffee Borman Lovell Mattingly Haise Swigert)
    @character_unique_traits[:first_name] = @male_first_names.sample if @character_unique_traits[:sex] == "male"
    @character_unique_traits[:first_name] = @female_first_names.sample if @character_unique_traits[:sex] == "female"
    @character_unique_traits[:last_name] = @last_names.sample unless @last_names.nil?
  end
  # List characters. Class method.
  def self.list_characters
    Say.negative "There are no characters defined!" if $characters.nil?
    Say.bold "Current characters:"
    $characters.each_with_index do |c,i|
      puts "#{i}: #{c.display}"
    end
  end
  def self.select_character
    Say.bold "Select a character from the following available."
    #Say.array($characters)
    $you = Say.get_with_array($characters)
  end
  def self.select_race
    Say.bold "Select your Race"
    Say.text "Available choices are:"
    result = Say.get_with_array(AVAILABLE_RACES)
    if AVAILABLE_RACES.include?(result)
      return result
    else
      Say.negative "Your choice #{result} is not an available race. Please select again."
      select_race
    end
  end
  def self.select_class
    Say.bold "Select your Class"
    result = Say.get_with_array(AVAILABLE_CLASSES)
    if AVAILABLE_CLASSES.include?(result)
      return result
    else
      Say.negative "Your choice #{result} is not an available class. Please select again."
      select_class
    end

  end
  def self.construct_character(race,p_class)
    $characters << (eval("#{race}_#{p_class}.new"))
    $you = $characters.last
  end

end

##
# Stock Races


class Dragonborn < Character
  def initialize
    @race = "Dragonborn"
    super
  end

  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end
end

class Dwarf < Character
  def initialize
    @race = "Dwarf"
    super
  end
  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end
end

class Eladrin < Character
  def initialize
    @race = "Eladrin"
    super
  end
  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end
end

class Elf < Character
  def initialize
    @race = "Elf"
    super
  end
  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
    @male_first_names = %w(Lucian Legalos)
    @female_first_names = %w(Leaf Rainy)
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end
end

class HalfElf < Character
  def initialize
    @race = "Half-Elf"
    super
  end
  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end
end

class Halfling < Character
  def initialize
    @race = "Halfling"
    super
  end
  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end
end

class Human < Character
  def initialize
    @race = "Human"
    super
  end
  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end
end


class Tiefling < Character
  def initialize
    @race = "Tiefling"
    super
  end
  # Shim methods. These are ran prior to stat generation. For race-specific names and such.
  def load_initial_race_variables
  end

  # Shim methods. These are ran *after* stat generation. For +2 char modifers etc.
  def load_race_modifiers
  end
end



##
# Character races should go here.
# Elf_Cleric < Elf < Character
# Dragonborn_Fighter < Dragonborn < Character


class Dragonborn_Fighter < Dragonborn
  include Fighter
  def initialize
    super
  end
end

class Dragonborn_Wizard < Dragonborn
  include Wizard
  def initialize
    super
  end
end

class Dwarf_Fighter < Dwarf
  include Fighter
  def initialize
    super
  end
end

class Dwarf_Wizard < Dwarf
  include Wizard
  def initialize
    super
  end
end

class Eladrin_Fighter < Eladrin
  include Fighter
  def initialize
    super
  end
end

class Eladrin_Wizard < Eladrin
  include Wizard
  def initialize
    super
  end
end

class Elf_Fighter < Elf
  include Fighter
  def initialize
    super
  end
end

class Elf_Wizard < Elf
  include Wizard
  def initialize
    super
  end
end

class HalfElf_Fighter < HalfElf
  include Fighter
  def initialize
    super
  end
end

class HalfElf_Wizard < HalfElf
  include Wizard
  def initialize
    super
  end
end

class Halfling_Fighter < Halfling
  include Fighter
  def initialize
    super
  end
end

class Halfling_Wizard < Halfling
  include Wizard
  def initialize
    super
  end
end

class Human_Fighter < Human
  include Fighter
  def initialize
    super
  end
end

class Human_Wizard < Human
  include Wizard
  def initialize
    super
  end
end



class Tiefling_Fighter < Tiefling
  include Fighter
  def initialize
    super
  end
end

class Tiefling_Wizard < Tiefling
  include Wizard
  def initialize
    super
  end
end

# Crap for testing goes here.

#Say.bold "Welcome to the character generator!"
#Say.text "Nothing really"
#Say.negative "Uhoh, something has gone wrong!"
#Say.positive "Yay!"
#Say.command "Enter your name"
#Say.array %w(Cheese Nikky Nixon)
#Say.positive(Dice.roll 6,1)



#race_choice = Character.select_race
#class_choice = Character.select_class
#you = Character.construct_character(race_choice,class_choice)
#you.display
#puts $characters
#Character.greet
#race_choice = Character.select_race
#class_choice = Character.select_class
#you = Character.construct_character(race_choice,class_choice)
#puts $characters
#Character.list_characters
Simulator.menu
