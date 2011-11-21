require "json"

class User < ActiveRecord::Base

	before_save :save_structures

	# {'0':{'c' => 3, 't' => 45, 'v' => 0}, ...}
	def level_instances
		@level_instances = JSON.parse(super || '{}') unless @level_instances
		@level_instances
	end
	def level_instances=(hash)
		@level_instances = hash
	end
	def get_level_instance_by_number(number)
		lvl = level_instances[number]
		if lvl
			lvl = LevelInstance.new(lvl)
			lvl.data = Level.by_number(number)
		end
		lvl
	end

	#  {"123" : {"id":123, "x":2, "y":5}, ... }
	def rewards
		@rewards = JSON.parse(super || '{}') unless @rewards
		@rewards
	end
	def rewards=(hash)
		@rewards = hash
	end

	# каждый вызов метода создает новое рандомное значение, автозаписывемое в базу
	def get_roll()
		roll = self.roll.to_i
		roll = (self.uid.to_i + 1024) if roll == 0
		self.roll = roll = ((roll * 16147) % 2147483647).to_i
		(roll.to_f / 2147483647)
	end


	def save_structures
		self['level_instances'] = JSON.fast_generate(@level_instances) 	if @level_instances
		self['rewards'] = JSON.fast_generate(@rewards) 			if @rewards
	end

	def add_reward(reward)
		rewards[reward.id] = {'id' => reward.id, 'x' => reward.x, 'y' => reward.y}
	end

	def add_level_instance(level_instance)
		if level_instance.success
			level_instances[level_instance.levelDef.number] = {'c' => level_instance.carrotHarvested,
															   't' => level_instance.timeSpended,
															   'v' => level_instance.levelDef.version}
		end
	end
end