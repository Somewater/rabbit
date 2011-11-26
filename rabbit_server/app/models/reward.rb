class Reward

	TYPE_FAST_TIME = 	'fast_time'
	TYPE_ALL_CARROT = 	'all_carrots'
	TYPE_CARROT_PACK = 	'carrot_pack'
	TYPE_SPECIAL = 		'special'

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