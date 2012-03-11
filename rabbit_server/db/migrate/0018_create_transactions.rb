class CreateTransactions < ActiveRecord::Migration
	def self.up
		if(APP_ENV != 'test')
			Application.connect_to "stat" do
				create_table :transactions do |t|
					t.string :uid, :null => false
					t.integer :net, :null => false
					t.string :status # статус (сюда дописываем, что происходит с транзакцией, т.е. не затирая предыдущие статусы)
					t.integer :product_type, :default => 0 # какой игровой товар покупаем (0 - круглики)
					t.integer :quantity # сколько игрового товара покупаем
					t.integer :netmoney # сколько валюты сети получаем
					t.integer :netmoney_type, :default => 0 # тип валюты сети (если в валюте нет одной унифицированной, например мейлики и рубли)
					t.integer :net_transaction_id # выдается соц. сетью на оснгове ее внутрениих соображений
					t.datetime :created_at
					t.datetime :updated_at
				end
			end
		else
	    	# nothing
		end
	end

	def self.down
		if(APP_ENV != 'test')
			Application.connect_to "stat" do
				drop_table 'transactions'
			end
		else
			# nothing
		end
	end
end
