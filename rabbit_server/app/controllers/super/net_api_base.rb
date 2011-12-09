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

	def can_allocate_uid
		false # нельзя сервером назначать uid, т.к. они должны предоставляться соц сетью
	end
end