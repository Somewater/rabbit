class AddLevelVisibleColumn < ActiveRecord::Migration
	def self.up
		add_column :levels, :visible, :boolean, :default => true
	end

	def self.down
		remove_column :levels, :visible
	end
end
