class AddLevelImageColumn < ActiveRecord::Migration
	def self.up
		add_column :levels, :image, :string
	end

	def self.down
		remove_column :levels, :image
	end
end
