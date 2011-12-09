class EmbedApi < NetApiBase
	def self.id
		1
	end

	def can_allocate_uid
		true # сервер может самостоятельно назначать uid, т.к. все равно они не присваюваются сетью
	end

	BaseController.api_by_name[:embed] = BaseController.api_by_id[id.to_i] = self
end