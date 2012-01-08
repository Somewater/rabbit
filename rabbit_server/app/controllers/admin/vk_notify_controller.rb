class VkNotifyAdminController < AdminController::Base
	VK_NOTIFY_PATH = '/admin/vk/notify'

	def check_permissions()
		raise AuthError, "Illegal operation" if @admin_user.user.login != 'dev'
	end

	def self_binding
		binding
	end

	def call
		if(@request['action'] && @request['action'] =~ /create/)
			notify = Notify.new
			notify.attributes = @request['notify']
			notify.enabled = @request['notify']['enabled']
			notify.save
		elsif(@request['action'] && @request['action'] =~ /update/)
			notify = Notify.find(@request['notify']['id'])
			notify.attributes = @request['notify']
			notify.enabled = @request['notify']['enabled']
			notify.save
		elsif(@request['action'] && @request['action'] =~ /show/)
			@notify = Notify.find(@request['id'])
		elsif(@request['action'] && @request['action'] =~ /delete/)
			Notify.delete(@request['id']);
		end

		@notifyes = Notify.all
		template File.read("#{TEMPLATE_ROOT}/admin/vk_notify_admin_index.erb")
	end
end