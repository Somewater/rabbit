class NetApi
	
	# классы по net:int
	@@by_net = {}
	
	# массив классов, еще не добавленных в @@by_net
	@@unsorted_queue = []
	
	def self.inherited(base)
		@@unsorted_queue << base
	end
	
	def initialize()
	end

	def id
		self.class.id
	end

	# имя net api (совпадает с именем NetApi в конфигурационных файлах)
	def name
		nil
	end

	def can_allocate_uid
		false # нельзя сервером назначать uid, т.к. они должны предоставляться соц сетью
	end
	
	
	# проверить, правильно ли авторизовался пользователь (params - на будующее)
	def authorized?(uid, key, params = nil)
		true
	end
	
	# послать нотифай
	# target - массив или одиночный объект типа User или uid
	# @return нотифаи успешно отосланы, возвращает массив id-шников успешных получателей (либо true)
	def notify(target, text, params = nil)
		false	
	end
	
	# попытаться снять деньги с баланса пользователя (в валюте соц. сети)
	# user - User или uid в соц. сети
	# value - сумма для списания, в валюте соц сети
	# @return возврашает nil, если платеж произведен успешно, иначе текст ошибки
	def pay(user, value, params = nil)
		raise UnimplementedError, "Override me"	
	end
	
	####
	#
	#		STATIC
	#
	####
	
	def self.id
		raise UnimplementedError, "Override me"
	end
	
	# выдать соответствующий инстанс адаптера, соответствующего сети под заданным номером
	def self.by_net(net)
		# сначала пройтись по @@unsorted_queue
		if(@@unsorted_queue.size > 0)
			@@unsorted_queue.each do |clazz|
				@@by_net[clazz.id] = clazz.new	
			end
			@@unsorted_queue = []
		end
		net = 1 if (net.to_s =~ /local\:\w+/)
		@@by_net[net.to_i]
	end

	# для всех вариантов аргумента выдает массив стрингов id-шников
	def self.arg_to_ids(arg)
		if arg.is_a?(Array)
			if(arg.first.is_a?(User))
				arg.map{|u| u.uid }
			else
				arg.map{|a| a.to_s }
			end
		else
			if arg.is_a?(User)
				[arg.uid]
			else
				[arg.to_s]
			end
		end
	end
end
