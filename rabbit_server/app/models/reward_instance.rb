class RewardInstance < Reward

	attr_accessor :x, :y

	def initialize(reward)
		@x = 0
		@y = 0
		if reward.instance_of?(Reward)
			@id = reward.id.to_i
			@type = reward.type
			@degree = reward.degree.to_i
		else
			super(reward)
		end
	end
end