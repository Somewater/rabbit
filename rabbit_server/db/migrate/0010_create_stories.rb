class CreateStories < ActiveRecord::Migration
	def self.up
		create_table :stories do |t|
			t.integer :number, :null => false

			t.string :name
			t.string :description
			t.string :image

			t.integer :start_level, :null => false # включительно
			t.integer :end_level, :null => false   # включительно

			t.boolean :enabled, :default => false
		end

		add_index :stories, [:number], :unique => true
	end

	def self.down
		drop_table 'stories'
	end
end
