class EmbedApi < NetApiBase
	def self.id
		1
	end

	BaseController.api_by_name[:embed] = BaseController.api_by_id[id] = self
end