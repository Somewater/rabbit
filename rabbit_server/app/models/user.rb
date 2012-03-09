require "json"

class User < ActiveRecord::Base

	before_save :save_structures

	# {'0':{'c' => 3, 't' => 45, 'v' => 0, 's' => 1}, ...}
	def level_instances
		unless @level_instances
			str = self['level_instances']
			str = '{}' if !str || str.size == 0
			@level_instances = JSON.parse(str )
		end
		@level_instances
	end
	def level_instances=(hash)
		@level_instances = hash
	end
	def get_level_instance_by_number(number)
		lvl = level_instances[number.to_s]
		if lvl
			lvl = LevelInstance.new(lvl)
			lvl.data = Level.by_number(number)
		end
		lvl
	end

	#  {"123" : {"id":123, "x":2, "y":5 [, "n":1 ],  [, "flag":1]}, ... }   , где n - номер уровня, "flag":1 -  ревард следует показать юзеру
	def rewards
		unless @rewards
			str = self['rewards']
			str = '{}' if !str || str.size == 0
			@rewards = JSON.parse(str )
		end
		@rewards
	end
	def rewards=(hash)
		@rewards = hash
	end

	def offer_instances
		unless @offer_instances
			str = self['offer_instances']
			str = '{}' if !str || str.size == 0
			@offer_instances = JSON.parse(str )
		end
		@offer_instances
	end
	def offer_instances=(hash)
		@offer_instances = hash
	end

	def customize
		unless @customize
			str = self['customize']
			str = '{}' if !str || str.size == 0
			@customize = JSON.parse(str )
		end
		@customize
	end
	def customize=(hash)
		@customize = (hash || {}) # нельзя присвоить nil, тогда будет невозможно сказать что данные были изменены
	end

	def items
		unless @items
			str = self['items']
			@items = {}
			if str
				str.split(',').each do |pair|
					pair = pair.split(':')
					@items[pair.first.to_i] = pair.last.to_i
				end
			end
		end
		@items
	end
	def items=(hash)
		@items = (hash || {}) # нельзя присвоить nil, тогда будет невозможно сказать что данные были изменены
	end


	# каждый вызов метода создает новое рандомное значение, автозаписывемое в базу
	def get_roll()
		debug = roll = self.roll.to_i
		roll = ((self.uid.size > 9 ? self.uid[-9..-1] : self.uid).to_i).abs + 1024 if roll < 1024
		self.roll = roll = ((roll * 16147) % 2147483647).to_i
		result = (roll.to_f / 2147483647)
		# Application.logger.debug "ROLL #{debug} => #{roll} (#{result})"
		Application.trace("ROLL #{debug} => #{roll} (#{result})")
		result
	end


	def save_structures
		self['level_instances'] = JSON.fast_generate(@level_instances) 	if @level_instances
		self['rewards'] = JSON.fast_generate(@rewards) 			if @rewards
		self['offer_instances'] = JSON.fast_generate(@offer_instances) if @offer_instances
		self['customize'] = JSON.fast_generate(@customize) if @customize
		self['items'] = @items.map{|k,v|"#{k.to_i}:#{v.to_i}"}.join(',') if @items
	end

	def clear_structures
		@rewards = nil
		@level_instances = nil
		@offer_instances = nil
		@customize = nil
		@items = nil
	end

	def reload(options = nil)
		super(options)
		clear_structures()
	end

	# обеспечивает перезаписывание старого значения новым
	def add_reward_instance(reward_instance)
		rewards[reward_instance.id.to_s] = {'id' => reward_instance.id,
											'x' => reward_instance.x,
											'y' => reward_instance.y,
											'n' => reward_instance.level}
	end

	# обеспечивает перезаписывание старого значения новым
	def add_level_instance(level_instance)
		if level_instance.success
			level_instances[level_instance.levelDef.number.to_s] = {'c' => level_instance.carrotHarvested,
															   't' => level_instance.timeSpended,
															   'v' => level_instance.version,
															   's' => level_instance.stars}
		end
	end

	# добавляет оффер только если нет такого же
	def add_offer_instance(offer)
		if(self.offer_instances[offer.id])
			raise LogicError, "Offer id #{offer.id} already created"
		else
			self.offer_instances[offer.id] = {}#'x' => offer.x,     # временно пишем пустые объекты,
											   #'y' => offer.y,     # т.к. id оффера однозначно сигнализиурет
											   #'n' => offer.level} # всю информацию о нем
			self.offers += 1
		end
	end

	def set_customize(type, id)
		customize[type.to_s] = id.to_i
	end

	def get_customize(type)
		customize[type.to_s] || 0
	end

	# спецально для выдачи инфы о друге, только важнейшая информация, не включающая сериализованные поля "level_instances", "rewards"
	def to_short_json
		hash = {};
		hash['level'] = self.level
		hash['score'] = self.score
		hash['uid'] = self.uid
		hash['stars'] = self.stars
		hash
	end

	# полная инеформация о пользователе
	def to_json
		hash = self.to_short_json
		hash['day_counter'] = self.day_counter
		hash['friends_invited'] = self.friends_invited
		hash['money'] = self.money
		hash['postings'] = self.postings

		hash['level_instances'] = @level_instances ? @level_instances : self['level_instances'] # если структуры уже созданы (заранее), то отдаем их
		hash['rewards'] = @rewards ? @rewards : self['rewards']
		hash['offer_instances'] = @offer_instances ? @offer_instances : self['offer_instances']
		hash['customize'] = @customize ? @customize : self['customize']

		hash['offers'] = self.offers
		hash['roll'] = self.roll
		hash['tutorial'] = self.tutorial
		hash['items'] = @items ? @items.map{|k,v|"#{k}:#{v}"}.join(',') : self['items']
		hash
	end

	def self.find_by_uid(uid, net)
		User.where(:uid => uid.to_s, :net => net.to_i).first
	end

	# всем ревардам юзера удалить флаг "flag", если таковой имеется
	def clear_all_flags
		if @rewards
			@rewards.each{|k,v| v.delete('flag') if v['flag']}
		else
			# более быстрый способ - изменить несериализвоанную строку
			self['rewards'] = self['rewards'].gsub(/,"flag":\d+/,'')
		end
	end

	def add_item(id, quantity = 1)
		items[id.to_i] = (items[id.to_i] || 0) + quantity.to_i
	end

	def delete_item(id, quantity = 1)
		raise LogicError, "Wrong delete quantity" unless quantity > 0

		q = self.items[id.to_i].to_i
		raise LogicError, "Cant allocate #{quantity} items id=#{id}" if q < quantity

		if(q == quantity)
			self.items.delete(id.to_i)
		else
			self.items[id.to_i] = q - quantity
		end
	end

	# получить ссылку на инстанс NetApi, согласно соц. сети юзера
	def api
		NetApi.by_net(self.net)
	end
end