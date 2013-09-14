class AddTestColumnToTransactions < ActiveRecord::Migration
	def self.up
		add_column :transactions, :test, :boolean, :default => false
	end

	def self.down
		remove_column :transactions, :test
	end
end
