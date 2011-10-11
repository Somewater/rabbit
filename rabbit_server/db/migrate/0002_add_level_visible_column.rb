class AddLevelVisibleColumn < ActiveRecord::Migration
	def self.up
		create_table :levels do |t|
			t.string  :description

			t.integer :number,  :default => 0
			t.integer :version, :default => 0

			t.integer :width
			t.integer :height

			t.string  :author
			t.text	  :conditions
			t.text	  :group

			t.boolean :enabled, :default => true
		end

		add_column :levels, :visible, :boolean, :default => true
	end

	def self.down
		remove_column :users, :role
	end
end
