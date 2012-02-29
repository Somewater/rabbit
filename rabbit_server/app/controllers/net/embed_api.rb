class EmbedApi < NetApi
	def self.id
		1
	end

	def can_allocate_uid
		true # сервер может самостоятельно назначать uid, т.к. все равно они не присваюваются сетью
	end
end
