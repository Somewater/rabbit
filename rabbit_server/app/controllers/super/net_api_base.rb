class NetApiBase

	def initialize(params)
		@params = params
	end

	def self.id
		raise UnimplementedError, "Override me"
	end

	def id
		self.class.id
	end
end