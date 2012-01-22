class IndexAdminController < AdminController::Base
	def check_permissions()
		# всем можно смотреть
	end

	def call
		html do
				r = ""
				r += tag("p") { tag "a", :href => '/admin/errors', :value => 'errors' } if @admin_user.can?(AdminUser::PERMISSION_ERROR_TRACKER)
				r += tag("p") { tag "a", :href => '/admin/levels', :value => 'levels' } if @admin_user.can?(AdminUser::PERMISSION_LEVEL_TRACKER)
				r += tag("p") { tag "a", :href => '/admin/stories', :value => 'stories' } if @admin_user.can?(AdminUser::PERMISSION_STORIES_TRACKER)
				r += tag("p") { tag "a", :href => '/admin/logs', :value => 'logs' } if @admin_user.can?(AdminUser::PERMISSION_LOG_VIEW)
				r += tag("p") { tag "a", :href => '/admin/users', :value => 'users' } if @admin_user.can?(AdminUser::PERMISSION_USER_TRACKER)
				r += tag("p") { tag "a", :href => '/admin/admins', :value => 'admins' } if @admin_user.user.login == 'dev'
				r += tag("p") { tag "a", :href => '/admin/vk/notify', :value => 'notifyes' } if @admin_user.user.login == 'dev'
				r += tag("p") { tag "a", :href => '/admin/stat', :value => 'stat' } if @admin_user.can?(AdminUser::PERMISSION_STAT_VIEW)
				r
			end
	end
end