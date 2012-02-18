class AddCustomizeFields < ActiveRecord::Migration
	def self.up

		# Хэш кастомных объектов, принадлежащих юзеру в формате
		# {"roof":3434, "floor":0}   # где 0, nil или отсутствие значения сигнализирует дефолтную вещь
		add_column :users, :customize, :text
	end

	def self.down
		remove_column :users, :customize
	end
end
