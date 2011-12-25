class VkApi < NetApiBase

	def initialize(params)
		raise AuthError, "Wrong auth_key" if Digest::MD5.hexdigest('2732721_' + params['uid'] + '_' + 'kJ0AVDo3he9GhGlhkmha') != params['key']
		super(params)
	end

	def self.id
		2
	end

	BaseController.api_by_name[:vk] = BaseController.api_by_id[id.to_i] = self
end