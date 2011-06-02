require_relative '../../lib/dsl/loader.rb'
require 'spec_helper'

include DSL::Loader
describe DSL::Loader do
 
  describe 'when parsing a single simple Location' do
     
    let(:data) do
       lambda do
         location :town do
            name 'Viva La Vegas'
            desc 'A great town.'
         end 
       end
    end

    let(:locations) { parse(data) }
    subject { locations.first }
 
    it 'returns a single Location' do
      locations.length.should == 1
    end
    
    its(:name)            { should == :town }
    its(:long_name)       { should == 'Viva La Vegas' }
    its(:description)     { should == 'A great town.' }
    its(:parent_location) { should be_nil }
    its(:child_locations) { should be_empty }
    its(:connected_locations) { should be_empty }

    it { should_not have_action(:any) } 
         
    it 'still returns only a single Location' do
      locations.length.should == 1
    end
  end
 
  describe 'when parsing hierarchical Locations' do
    let(:data) do
      lambda do

        location :street do
          location :park do
            location :bank do
            end
          end

          location :house do
            location :door do
            end
          end
        end

      end
    end

    let(:locations) { parse(data) }

    it 'returns the correct number of Locations' do
      locations.length.should == 5
    end

    it 'returns the described Locations' do
      names = locations.map {|location| location.name}
      names.should include(:street, :park, :bank, :house, :door)
    end

    it 'return Locations that are correctly connected to their parent Location' do
       parent_hash = {:street => nil, :park => :street, :bank => :park, :house => :street, :door => :house}
      
       locations.each {|location| location.should satisfy {|arg| parent_hash[location.name] == location.parent_location_name}}              
    end

    it 'returns Locations that know their child Locations' do
      hash = {
        :street => [:park, :house],
        :park => [:bank],
        :bank => [],
        :house => [:door],
        :door => []
      }

      locations.each do |location|
        child_location_names = location.child_locations.map {|location| location.name }
        child_location_names.should == hash[location.name]
      end
    end

    it 'returns Locations that are connected to their parent Location and child Locations' do
      hash = {
        :street => [:park, :house],
        :park => [:street, :bank],
        :bank => [:park],
        :house => [:street, :door],
        :door => [:house]
      }

      locations.each do |location|
        location_names = location.connected_locations.map {|location| location.name }
        location_names.should == hash[location.name]
      end
    end
  end

  describe 'when parsing a Location that is remotely connected to another Location' do

    let(:data) do
      lambda do
        
        location :kitchen do
          remote_locations :living, :cellar
        end

        location :living do
        end

        location :cellar do
        end

      end
    end

    let(:locations) { parse(data) }
    let(:hash) do { 
        :kitchen => [:living, :cellar],
        :living => [:kitchen],
        :cellar => [:kitchen]
      }
    end

    it 'should return Locations that are correctly connected' do
      locations.each do |location|
        location.connected_location_names.should == hash[location.name]
      end
    end

    it 'should return Locations that are correctly know
        about the Locations they are remotely connected to' do
      locations.each do |location|
        location.connected_locations.should == location.remote_locations
      end
    end
  end
  
  describe 'when parsing a Location that includes an Item' do
    let(:data) do
      lambda do
        
        location :table do
          item :coin, 'A silver coin.'

          action :search do
            take :coin
          end
        end

      end
    end

    let(:loc) { parse(data).first }

    it 'returns a Location that has one Item' do
      loc.items.length == 1
    end

    context "then the Item's" do
      subject { loc.items[0] }

      its(:name)        { should == :coin }
      its(:description) { should == 'A silver coin.' }
    end

  end

  describe 'when parsing a Location that does not allow one to return' do
    let(:data) do
      lambda do
        
        location :hell do
          transition { blocked }   
        end

      end
    end

    let(:loc) { parse(data).first }

    it 'returns a Location whose transition is disabled' do
      transition = loc.transitions.first

      transition.from.should == :any
      transition.to.should == loc
      transition.allowed.should be_false
    end
  
  end
end