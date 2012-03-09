class AddItemsUserFields < ActiveRecord::Migration
	def self.up

		# хэш с числовыми ключами и значениями, формата "100:1,200:3,201:2"
		add_column :users, :items, :string
	end

	def self.down
		remove_column :users, :items
	end
end
