class RewardInstance < Reward

	attr_accessor :x, :y, :level

	def initialize(reward, lvl)
		@x = 0
		@y = 0
		@level = lvl.respond_to?(:number) ? lvl.number : lvl.to_i
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
		json
	end
end