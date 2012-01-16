class StatAdminController < AdminController::Base
	STAT_PATH = '/admin/stat'

	def check_permissions()
		raise AuthError, "Illegal operation" unless @admin_user.can?(AdminUser::PERMISSION_STAT_VIEW)
	end

	def self_binding
		binding
	end

	def call
		@names = Stat.select('name').group('name').map{|s| s.name }

		if(@request['name'])
			@name = @request['name']
			@stats = Stat.all(:conditions => ['name = ?', @name], :order => 'time DESC')
		end

		template(File.read("#{TEMPLATE_ROOT}/admin/stat_admin_show.erb"))
	end
end
