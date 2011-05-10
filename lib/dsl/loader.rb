require_relative '../location'
require_relative '../item_factory'

module DSL 
  module Loader

  @@parent = nil
  @@locations = []
  @@obj_stack = []
  @@item_factory = ItemFactory.new

  def current_obj
    @@obj_stack.last
  end

  def find_create_location(sym)
    location = @@locations.find {|l| l.name == sym}

    if location == nil then    
      location = Location.new
      location.name = sym
      location.long_name = sym.to_s
      
      @@locations << location
    end
  
    location
  end

  def location(sym)
    parent_location = current_obj
    location = find_create_location sym

    if parent_location != nil then
      location.parent_location = parent_location
      parent_location.child_locations << location
    end

    @@obj_stack.push location  

    yield # Here we let the DSL take-over again.

    @@obj_stack.pop
  end

  def name(text)
    current_obj.long_name = text
  end

  def desc(text)
    current_obj.description = text
  end

  def transition()
    t = current_obj.add_transition_from @@parent 

    if block_given? then
      block = Proc.new
      t.instance_eval(&block)
    end

    t
  end

  # shortcut for transition { on_enter { .. } }
  def on_enter()
    block = Proc.new()
 
    transition do
      on_enter(&block)
    end
  end

  def remote_locations(*names)
    names.each { |name| remote_location name }
  end

  def remote_location(name)
    location = find_create_location name
    current_obj.remote_locations << name

    if block_given? then
      @@parent = current_obj
      @@obj_stack.push location  
      yield 
      @@obj_stack.pop
      @@parent = nil
    end
  
  end
      
  def item(name, description = nil)
    item = @@item_factory.create(name)

    if description != nil then
      item.description = description
    end

    if block_given? then
      block = Proc.new
      item.instance_eval(&block)
    end

    current_obj.add_item item
  end

  def action(symbol, &block)
    current_obj.add_action(symbol, &block)
  end

  def parse_file(fileName)
    load fileName
    finish_parse 
  end
  
  def parse(block)
    block.call
    finish_parse
  end

  def find_location_named(name)
    @@locations.detect do |loc|
      loc.name == name
    end
  end

  # Replaces the names of remote locations
  # that have been temporarily stored in the list of
  # remote locations with the actual location objects.
  def replace_remote_location_names
    @@locations.each do |location|
      remote_locations = []

      location.remote_locations.each do |remote_location_name|
        remote_location = find_location_named remote_location_name

        if remote_location == nil then
          raise "Could not find remote location '#{remote_location_name}'"
        else
          remote_locations << remote_location
        end

      end
     
      location.remote_locations = remote_locations
    end
  end

  # Makes sure that all remote locations
  # are connected to eachother.
  def mirror_remote_locations
    @@locations.each do |location|
      location.remote_locations.each do |remote_location|
 
        if not remote_location.remote_locations.include?(location) then
          remote_location.remote_locations << location
        end

      end
    end
  end

  def finish_parse
    replace_remote_location_names
    mirror_remote_locations

    locations = @@locations.clone
    @@locations.clear
    locations
  end

  end
end

