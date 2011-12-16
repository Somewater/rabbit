class CreateAdminRoles < ActiveRecord::Migration
	def self.up
		create_table :admins do |t|
			t.string  :login, :null => false
			t.string  :password, :null => false
			t.integer :permissions, :default => 0
			t.integer :level_low, :default => 1
			t.integer :level_high, :default => 999999
			
			t.datetime :created_at
			t.datetime :updated_at
		end
	end

	def self.down
		drop_table 'admins'
	end
end
