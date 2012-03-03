class AddStarsUserFields < ActiveRecord::Migration
	def self.up

		add_column :users, :stars, :integer,   :default => 0
	end

	def self.down
		remove_column :users, :stars
	end
end
