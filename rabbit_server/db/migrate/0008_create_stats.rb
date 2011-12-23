class CreateStats < ActiveRecord::Migration
	def self.up
		if(APP_ENV != 'test')
			Application.connect_to "stat" do
				create_table :stats do |t|
					t.string  :name, :null => false
					t.integer :time, :null => false
					t.integer :value, :default => 0
				end
				
				add_index :stats, [:name, :time], :unique => true
			end
		else
			create_table :stats do |t|
				t.string  :name, :null => false
				t.integer :time, :null => false
				t.integer :value, :default => 0
			end
				
			add_index :stats, [:name, :time], :unique => true	
		end
	end

	def self.down
		if(APP_ENV != 'test')
			Application.connect_to "stat" do
				drop_table 'stats'
			end
		else
			drop_table 'stats'
		end
	end
end
