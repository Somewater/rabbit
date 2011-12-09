class AddDayCounterColumn < ActiveRecord::Migration
	def self.up
		add_column :users, :day_counter, :integer, :default => 0
	end

	def self.down
		remove_column :users, :day_counter
	end
end
