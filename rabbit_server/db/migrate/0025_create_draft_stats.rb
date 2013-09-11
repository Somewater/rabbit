class CreateDraftStats < ActiveRecord::Migration
	def self.up
		create_table :level_pass_stats do |t|
			t.string :uid

			t.integer :level
			t.integer :time
			t.integer :carrots
			t.integer :stars
			t.string :powerups
			t.string :flag

			t.boolean :success
			t.boolean :first

			t.datetime :created_at
		end

		create_table :new_user_stats do |t|
			t.string :uid

			t.string :referer
			t.string :source
			t.string :adv
			t.datetime :created_at
		end
	end

	def self.down
		drop_table 'level_pass_stats'
		drop_table 'new_user_stats'
	end
end
