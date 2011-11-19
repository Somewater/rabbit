class RewardInstance < Reward

	attr_accessor :x, :y

	def initialize(reward)
		@x = 0
		@y = 0
		super(reward)
	end
end