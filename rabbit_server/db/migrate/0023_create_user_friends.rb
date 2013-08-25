class CreateUserFriends < ActiveRecord::Migration
	def self.up
		create_table :user_friends do |t|
			t.string :user_uid, :null => false
			t.string :friend_uid, :null => false
			t.boolean :accepted, :default => false
			t.datetime :last_daily_bonus
		end

		add_index :user_friends, [:user_uid, :friend_uid], :unique => true
	end

	def self.down
		drop_table :user_friends
	end
end
