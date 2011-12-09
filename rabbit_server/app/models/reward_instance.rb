class RewardInstance < Reward

	FLAG_NEED_SHOW = 1 # необходимо показать ревард юзеру, т.к. ревард был выдал "оффлайн"

	attr_accessor :x, :y, :level

	def initialize(reward, lvl)
		@x = 0
		@y = 0
		@level = lvl.respond_to?(:number) ? lvl.number : lvl.to_i
		@flag = nil
		if reward.instance_of?(Reward)
			@id = reward.id.to_i
			@type = reward.type
			@degree = reward.degree.to_i
		else
			super(reward)
		end
	end

	def to_json
		json = super
		json.merge!({'x' => @x, 'y' => @y, 'n' => @level})
		json['flag'] = true if @flag && @flag > 0
		json
	end

	def flag=(v)
		@flag = v
	end
	def flag
		@flag ? @flag : 0
	end
end