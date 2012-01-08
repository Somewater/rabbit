class CreateNotifyes < ActiveRecord::Migration
	def self.up
		create_table :notifyes do |t|
			t.string  :message, :null => false
			t.string  :mode
			t.integer :priority, :default => 0
			t.integer :position, :default => 0
			t.integer :net, :default => 1
			t.boolean :enabled, :default => true

			t.datetime :created_at
			t.datetime :updated_at
		end
	end

	def self.down
		drop_table 'notifyes'
	end
end
