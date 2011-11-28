class CreateUsers < ActiveRecord::Migration
	def self.up
		create_table :users do |t|
			t.integer :net, :null => false
			t.string  :uid, :null => false
			t.string  :first_name
			t.string  :last_name
			
			# информация о пройденных уровнях в сериализованном виде:
			# {  "0":{"t":123, "c":23, "v":7, "s":1} ,...  }
			# t - время прохождения, секунды
			# c - морковок собрано
			# v - версия уровня, на момент рпохождения
			# s - звезд за уровень
			t.text    :level_instances#, :default => '{}'

			# Информация о полученных наградах
			# массив объектов вида: {"123" : {"id":123, "x":2, "y":5}, ... }
			t.text	  :rewards#, :default => '[]'

			# собранное число морковок
			t.integer :score,  :default => 0

			# игровая валюта (не реал)
			t.integer :money,  :default => 0

			# достигнутый уровень (т.е. какой левел Открыт, пройденный лвл+1)
			t.integer :level,  :default => 1

			# Число для осуществления рандома для конкретного юзера
			t.decimal :roll, :default => '0'

			# сколько привел друзей
			t.integer :friends_invited, :default => 0

			# сколько запостил сообщений
		    t.integer :postings, :default => 0

			t.datetime :created_at
			t.datetime :updated_at
		end

		add_index :users, [:uid, :net], :unique => true
	end

	def self.down
		drop_table 'users'
	end
end
