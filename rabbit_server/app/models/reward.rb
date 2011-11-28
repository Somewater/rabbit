class Reward

	TYPE_SPECIAL = 'special'            # специальные, непризовые объекты поляны (нора)
	TYPE_FAST_TIME = 'fast_time'    	# быстрое время прохождения уровня
	TYPE_ALL_CARROT = 'all_carrots'     # собрано морковок (интегрально по уровням)
	TYPE_CARROT_PACK = 'carrot_pack'    # собрано много морковок на уровне
	TYPE_FAMILIAR = 'familiar'			# заходил несколько дней подряд
	TYPE_POSTING = 'posting'            # запостил сообщения
	TYPE_REFERER = 'referer'            # пригласил друзей (дается пригласившему (!!!))
	TYPE_CONSOLING = 'consoling'        # утешительные призы

	attr_reader :id, :type, :degree

	def initialize(attrs)
		@id = attrs['id'].to_i
		@type = attrs['type']
		@degree = attrs['degree'].to_i
	end

	def to_json
		{'id' => @id, 'type' => @type, 'degree' => @degree}
	end
end