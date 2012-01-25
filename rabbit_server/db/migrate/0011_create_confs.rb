class CreateConfs < ActiveRecord::Migration
	def self.up
		create_table :confs do |t|
			t.string :name, :null => false
			t.text :value
			t.boolean :visible, :default => true
		end

		add_index :confs, [:name], :unique => true
	end

	def self.down
		drop_table 'confs'
	end
end
