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

	# каждый вызов метода создает новое рандомное значение, автозаписывемое в базу
	def get_roll()
		roll = self.roll.to_i
		roll = (self.uid.to_i + 1024).abs if roll < 1024
		self.roll = roll = ((roll * 16147) % 2147483647).to_i
		result = (roll.to_f / 2147483647)
		result
	end


	def save_structures
		self['level_instances'] = JSON.fast_generate(@level_instances) 	if @level_instances
		self['rewards'] = JSON.fast_generate(@rewards) 			if @rewards
	end

	def clear_structures
		@rewards = nil
		@level_instances = nil
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

	# спецально для выдачи инфы о друге, только важнейшая информация, не включающая сериализованные поля "level_instances", "rewards"
	def to_short_json
		hash = {};
		self.attributes.each{|k,v| hash[k] = v.to_s if k.to_s != 'level_instances' && k.to_s != 'rewards'}
		hash
	end

	# полная инеформация о пользователе
	def to_json
		hash = self.to_short_json
		hash['level_instances'] = self.level_instances
		hash['rewards'] = self.rewards
		hash
	end

	def self.find_by_uid(uid, net)
		User.where(:uid => uid.to_s, :net => net.to_i)[0]
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
end