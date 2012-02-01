class AddTutorialCounterToUser < ActiveRecord::Migration
	def self.up
		add_column :users, :tutorial, :integer, :default => 0
	end

	def self.down
		remove_column :users, :tutorial
	end
end
