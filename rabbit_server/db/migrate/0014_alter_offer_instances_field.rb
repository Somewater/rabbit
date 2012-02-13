class AlterOfferInstancesField < ActiveRecord::Migration
	def self.up
		change_column :users, :offer_instances, :text
	end

	def self.down
		# nothing
	end
end
