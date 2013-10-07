class NetApi
	
	# классы по net:int
	@@by_net = {}
	@@by_net_name = {}
	
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

	def on_event(uid, name, params= nil)

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
			process_unsorted_queue
		end
		net = 1 if (net.to_s =~ /local\:\w+/)
		@@by_net[net.to_i]
	end

	def self.by_net_name(name)
		# сначала пройтись по @@unsorted_queue
		if(@@unsorted_queue.size > 0)
			process_unsorted_queue
		end
		@@by_net_name[name.to_s]
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

	def self.process_unsorted_queue
		@@unsorted_queue.each do |clazz|
			next if @@by_net[clazz.id]
			instance = clazz.new
			@@by_net[clazz.id.to_i] = instance
			@@by_net_name[instance.name.to_s] = instance
		end
		@@unsorted_queue = []
	end

	def self.register(clazz)
		instance = clazz.new
		@@by_net[clazz.id.to_i] = instance
		@@by_net_name[instance.name.to_s] = instance
	end
end
