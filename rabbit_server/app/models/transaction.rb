# класс для логгирования денежных операций
class Transaction < ActiveRecord::Base

	establish_connection(DB_CONF['stat']) if(APP_ENV != 'test')

	def last_status
		s = self.status
		if(s)
			s.split(',').last
		else
			nil
		end
	end
	
	def	<<(stat)
		self.status = (self.status ? self.status + ',': '') + stat
	end

	def self.create_from(user, money, netmoney)
		t = Transaction.new
		t.uid = user.uid
		t.net = user.net
		t.quantity = money
		t.netmoney = netmoney
		t
	end
end