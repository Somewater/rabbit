class TemplateAdminController < AdminController::Base
	TEMPLATE_PATH = '/admin/tmplt'

	def check_permissions()
		raise AuthError, "Illegal operation" unless @admin_user.can?(0)
	end

	def self_binding
		binding
	end

	def call
		if(@request['action'] && @request['action'] =~ /create/)
			tmplt = Template.new
			tmplt.attributes = @request['tmplt']
			tmplt.enabled = @request['tmplt']['enabled'] # boolean
			tmplt.save
		elsif(@request['action'] && @request['action'] =~ /update/)
			tmplt = Template.find(@request['tmplt']['id'])
			tmplt.attributes = @request['tmplt']
			tmplt.enabled = @request['tmplt']['enabled'] # boolean
			tmplt.save
		elsif(@request['action'] && @request['action'] =~ /show/)
			@tmplt = Template.find(@request['id'])
		elsif(@request['action'] && @request['action'] =~ /delete/)
			Template.delete(@request['id']);
		end

		@templates = Template.all
		template File.read("#{TEMPLATE_ROOT}/admin/tmplt.erb")
	end
end