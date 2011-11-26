# ООП представление для объектов поля user.level_instances
class LevelInstance

	# констатны различных причин заверщения уровня
	LEVEL_SUCCESS_FINISH = "LEVEL_SUCCESS_FINISH" # уровень пройден
	LEVEL_FATAL_CARROT 	= "LEVEL_FATAL_CARROT" # кто-то украл все морковки
	LEVEL_FATAL_LIFE 	= "LEVEL_FATAL_LIFE" # кролик погиб
	LEVEL_FATAL_TIME 	= "LEVEL_FATAL_TIME" # время вышло

	attr_reader 	:levelDef			# инстанс класса Level

							### ДАННЫЕ СОХРАНЯЮЩИЕСЯ В БАЗЕ ###
					#:timeSpended,       # число миллисекунд с момента старта игры
					#:carrotHarvested,   # морковок собрано на уровне
					#:version

	attr_accessor	:success           #
					#:finalFlag,         # КОнстанта из класса LevelConditionsManager
					#:aliensPassed,      # сколько врагов было на уровне (и, соответственно, пройдено)
					#:stars,             # Сколько звездочек получено за прохождение уровня (минимум 1, если уровень завершен успешно)
	attr_reader		:rewards            # бонусы за прохождение уровня (array of RewardInstanceDef)

	def initialize(* args)
		@rewards = []
		if(args)
			args.each{|hash| self.data = hash }
		end
	end

	def data=(hash)
		if hash.is_a? Level
			@levelDef = hash
		else
			hash.each do |key, value|
				key = key.to_sym
				if key == :number
					@levelDef = Level.by_number(value)
				elsif key == :c
					@carrotHarvested = value.to_i
				elsif key == :t
					@timeSpended = value.to_i
				elsif key == :v
					@version = value.to_i
				elsif self.respond_to? key
					self.instance_variable_set("@#{key}", value)
				else
					raise FormatError, "Unsupported key '#{key}'"
				end
			end
		end
	end

	def carrotHarvested
		@carrotHarvested ? @carrotHarvested.to_i : -1
	end

	def timeSpended
		@timeSpended ? @timeSpended.to_i : -1
	end

	def version
		@version ? @version.to_i : -1
	end

	def to_json
		json = {'number' => @levelDef.number,
				'carrotHarvested' => self.carrotHarvested,
				'timeSpended' => self.timeSpended,
				'success' => self.success,
				'version' => @levelDef.version}
		json['rewards'] = @rewards.map{|r| r.to_json }
		json
	end
end
