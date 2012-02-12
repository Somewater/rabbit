class AddOfferFields < ActiveRecord::Migration
	def self.up

		#
		# Хэш оферов (элементы хэша сериализуются в оффер-инстансы)
		# индексирование происходит по id оффера
		# который, в свою очередь, есть функция x, y, level параметров оффера
		add_column :users, :offer_instances, :string

		add_column :users, :offers, :integer, :default => 0
	end

	def self.down
		remove_column :users, :offer_instances
		remove_column :users, :offers
	end
end
