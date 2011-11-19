class Reward

	TYPE_FAST_TIME = 	'fast_time'
	TYPE_ALL_CARROT = 	'all_carrots'
	TYPE_CARROT_PACK = 	'carrot_pack'
	TYPE_SPECIAL = 		'special'

	attr_reader :id, :type, :degree, :index

	def initialize(attrs)
		@id = attrs['id'].to_i
		@type = attrs['type']
		@degree = attrs['degree'].to_i
		@index = attrs['index'].to_i
	end
end