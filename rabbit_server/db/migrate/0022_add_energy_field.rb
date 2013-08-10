class AddEnergyField < ActiveRecord::Migration
	def self.up

		add_column :users, :energy, :integer, :default => 0
		add_column :users, :energy_last_gain, :datetime
	end

	def self.down
		remove_column :users, :energy
		remove_column :users, :energy_last_gain
	end
end
