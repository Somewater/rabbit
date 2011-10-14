class AddLevelCreatedAtColumn < ActiveRecord::Migration
	def self.up
		add_column :levels, :created_at, :boolean, :default => true
	end

	def self.down
		remove_column :levels, :created_at
	end
end
