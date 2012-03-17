class CreateFriendStorages < ActiveRecord::Migration
	def self.up
		create_table :friend_storages do |t|
			t.string :uid, :null => false
			t.integer :net, :null => false
			t.text :friends # очень очень длинный массив друзей юзера "1212,3443,7657567,53443,23"
			t.integer :last_day
			t.text :rewarded # массив награжденных в last_day человек
		end

		add_index :friend_storages, [:uid, :net], :unique => true
	end

	def self.down
		drop_table :friend_storages
	end
end
