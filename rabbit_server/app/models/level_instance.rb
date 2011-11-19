# ООП представление для объектов поля user.level_instances
class LevelInstance

	# констатны различных причин заверщения уровня
	LEVEL_SUCCESS_FINISH = "LEVEL_SUCCESS_FINISH" # уровень пройден
	LEVEL_FATAL_CARROT 	= "LEVEL_FATAL_CARROT" # кто-то украл все морковки
	LEVEL_FATAL_LIFE 	= "LEVEL_FATAL_LIFE" # кролик погиб
	LEVEL_FATAL_TIME 	= "LEVEL_FATAL_TIME" # время вышло

	attr_reader :levelDef,			# инстанс класса Level

						### ДАННЫЕ СОХРАНЯЮЩИЕСЯ В БАЗЕ ###
				:timeSpended,       # число миллисекунд с момента старта игры
				:carrotHarvested,   # морковок собрано на уровне

				:success,           #
				:finalFlag,         # КОнстанта из класса LevelConditionsManager
				:aliensPassed,      # сколько врагов было на уровне (и, соответственно, пройдено)
				:stars,             # Сколько звездочек получено за прохождение уровня (минимум 1, если уровень завершен успешно)
				:rewards            # бонусы за прохождение уровня (array of RewardDef)

	def initialize(* args)
		@rewards = []
		if(args)
			args.each{|hash| self.data = hash }
		end
	end

	def data=(hash)
		if hash.is_a? Level
			@levelDef = Level
		else
			hash.each do |key, value|
				key = key.to_sym
				if key == :number
					@levelDef = Level.by_number(value)
				elsif key == :c
					@carrotHarvested = value
				elsif key == :t
					@timeSpended = value
				elsif self.respond_to? key
					self.instance_variable_set(key, value)
				else
					raise FormatError, "Unsupported key '#{key}'"
				end
			end
		end
	end

end