class UsersAdminController < AdminController::Base
	USERS_PATH = '/admin/users'

	def check_permissions()
		raise AuthError, "Illegal operation" unless @admin_user.can?(AdminUser::PERMISSION_USER_TRACKER)
	end

	def self_binding
		binding
	end

	def call

		if(@request['show'] && @request['show'] =~ /\d+/)
			if(@request['net'])
				@user = User.find_by_uid(@request['uid'] ? @request['uid'] : @request['show'], @request['net'])
			else
				@user = User.find(@request['show'])
			end
			template File.read("#{TEMPLATE_ROOT}/admin/users_admin_show.erb")
		elsif(@request['edit'] && @request['edit'] =~ /\d+/)
			@user = User.find(@request['edit'])
			@request['user']['rewards'] = JSON.parse(@request['user']['rewards']) if @request['user']['rewards']
			@request['user']['level_instances'] = JSON.parse(@request['user']['level_instances']) if @request['user']['level_instances']
			@user.update_attributes(@request['user'])
			@user.save
			template File.read("#{TEMPLATE_ROOT}/admin/users_admin_show.erb")
		elsif(@request['clear'] && @request['clear'].size > 0)
			@user = User.find(@request['id'])
			@user.level_instances = {} if @request['clear'].index('l')
			@user.rewards = {} if @request['clear'].index('r')
			@user.save
			template File.read("#{TEMPLATE_ROOT}/admin/users_admin_show.erb")
		elsif(@request['delete'] && @request['delete'] =~ /\d+/)
			User.delete( @request['delete'])
			@users = []#User.all
			template File.read("#{TEMPLATE_ROOT}/admin/users_admin_index.erb")
		else
			@users = []#User.all
			template File.read("#{TEMPLATE_ROOT}/admin/users_admin_index.erb")
		end
	end
end