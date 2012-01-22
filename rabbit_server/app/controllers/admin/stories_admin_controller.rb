class StoriesAdminController < AdminController::Base
	STORIES_PATH = '/admin/stories'

	def check_permissions()
		raise AuthError, "Illegal operation" unless @admin_user.can?(AdminUser::PERMISSION_STORIES_TRACKER)
	end

	def self_binding
		binding
	end

	def call
		if(@request['action'] && @request['action'] =~ /create/)
			check_attributes_hash(@request['story'])
			story = Story.new
			story.attributes = @request['story']
			story.enabled = @request['story']['enabled'] # boolean
			story.save
		elsif(@request['action'] && @request['action'] =~ /update/)
			check_attributes_hash(@request['story'])
			story = Story.find(@request['story']['id'])
			story.attributes = @request['story']
			story.enabled = @request['story']['enabled'] # boolean
			story.save
		elsif(@request['action'] && @request['action'] =~ /show/)
			@story = Story.find(@request['id'])
		elsif(@request['action'] && @request['action'] =~ /delete/)
			Story.delete(@request['id']);
		end

		@stories = Story.all(:order => 'number')
		template File.read("#{TEMPLATE_ROOT}/admin/stories_admin_index.erb")
	end

	def check_attributes_hash(hash)
		raise LogicError, "start level = 0" if hash['start_level'].to_i == 0
		raise LogicError, "end level = 0" if hash['end_level'].to_i == 0
		raise LogicError, "start level >= end level numver" if hash['start_level'].to_i >= hash['end_level'].to_i
	end
end