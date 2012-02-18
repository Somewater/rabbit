class ConfAdminController < AdminController::Base
	CONF_PATH = '/admin/config'

	def check_permissions()
		raise AuthError, "Illegal operation" if @admin_user.user.login != 'dev'
	end

	def self_binding
		binding
	end

	def call
		if(@request['action'] && @request['action'] =~ /create/)
			conf = Conf.new
			conf.attributes = @request['conf']
			conf.visible = @request['conf']['visible'] # boolean
			conf.save
			self.clear_cache()
		elsif(@request['action'] && @request['action'] =~ /update/)
			conf = Conf.find(@request['conf']['id'])
			conf.attributes = @request['conf']
			conf.visible = @request['conf']['visible'] # boolean
			conf.save
			self.clear_cache()
		elsif(@request['action'] && @request['action'] =~ /show/)
			@conf = Conf.find(@request['id'])
		elsif(@request['action'] && @request['action'] =~ /delete/)
			Conf.delete(@request['id']);
			self.clear_cache()
		end

		@confs = Conf.all
		template File.read("#{TEMPLATE_ROOT}/admin/conf_admin_index.erb")
	end

	def clear_cache()
		Conf.clear_cache()
		ConfManager.instance.clear_cache()
		ConfigGenerator.clear_cache()
	end
end