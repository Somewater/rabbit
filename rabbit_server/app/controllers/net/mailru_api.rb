class MailryApi < NetApiBase

	def initialize(params)
		raise AuthError, "Wrong auth_key" if Digest::MD5.hexdigest('649836' + '_' + params['uid'] + '_' + 'c0cbe717f8138e1c32d9aea6d6ec2891') != params['key']
		super(params)
	end

	def self.id
		3
	end

	BaseController.api_by_name[:mailru] = BaseController.api_by_id[id.to_i] = self
end