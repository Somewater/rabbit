class CreateBaseStructure < ActiveRecord::Migration
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
		
		if(APP_ENV != 'test')
			Application.connect_to "stat" do
				create_table :errors do |t|
					t.string  :title
					t.text :content
					t.text :resolution

					t.string :images
					t.integer :resolved, :default => 0

					t.string  :author
				end
			end
		end
	end

	def self.down
		drop_table 'levels'
		
		if(APP_ENV != 'test')
			Application.connect_to "stat" do
				drop_table 'errors'
			end
		end
	end
end
