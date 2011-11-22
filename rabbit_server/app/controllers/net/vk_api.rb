class VkApi < NetApiBase

	def self.id
		2
	end

	BaseController.api_by_name[:vk] = BaseController.api_by_id[id.to_i] = self
end