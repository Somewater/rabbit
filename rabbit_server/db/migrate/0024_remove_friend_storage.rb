class RemoveFriendStorage < ActiveRecord::Migration
	def self.up
		drop_table :friend_storages
	end

	def self.down
		create_table :friend_storages do |t|
			t.string :uid, :null => false
			t.integer :net, :null => false
			t.text :friends
			t.integer :last_day
			t.text :rewarded
		end

		add_index :friend_storages, [:uid, :net], :unique => true
	end
end
