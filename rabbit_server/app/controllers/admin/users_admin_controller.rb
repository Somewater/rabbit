class UsersAdminController < AdminController::Base
	USERS_PATH = '/admin/users'

	def self_binding
		binding
	end

	def call
		@users = User.all
		template File.read("#{TEMPLATE_ROOT}/admin/users_admin_index.erb")
	end
end