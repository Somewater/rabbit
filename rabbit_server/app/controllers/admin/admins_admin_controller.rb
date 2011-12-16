class AdminsAdminController < AdminController::Base
	ADMINS_PATH = '/admin/admins'

	def check_permissions()
		raise AuthError, "Illegal operation" if @admin_user.user.login != 'dev'
	end

	def self_binding
		binding
	end

	def call
		@users = Admin.all
		template File.read("#{TEMPLATE_ROOT}/admin/admins_admin_index.erb")
	end
end