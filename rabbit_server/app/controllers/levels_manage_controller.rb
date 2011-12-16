class LevelsManageController < BaseController

	def authorized
		raise AuthError, "Wrong admin password" unless check_password
	end

	def process
		case @json['operation']
			when 'create'
				create
			else
				raise MethodError, "Undefined submethod '#{@json['operation']}'"
		end
	end

private
	def check_password
		pair =  (@json['password'] || '').split(/\s+/)
		admin_user = AdminUser.new({'cookies' => {},
				'params' => {'login' => pair[0],
							 'password' => pair[1]}})

		if DEVELOPMENT
			@author = 'nobody'
			true
		elsif admin_user.authorized? == :login
			raise AuthError, "Unauthorized action" unless admin_user.can?(AdminUser::PERMISSION_LEVEL_SAVE)
			raise AuthError, "Illegal level number #{@json['number']}. Must between #{admin_user.user.level_low}-#{admin_user.user.level_high}" \
			 					unless @json['number'].to_i < admin_user.user.level_low || @json['number'].to_i > admin_user.user.level_high
			@author = admin_user.user.login
			true
		else
			false
		end
	end

	def create
		# Левел с максимальной версией
		head_level = Level.find(:first, :conditions => "number = #{@json['number']}", :order => "version desc")
		version = (head_level ? head_level.version + 1 : 0)
		level = Level.new({
							:number => @json['number'],
							:description => @json['description'],
							:version => version,
							:width => @json['width'],
							:height => @json['height'],
							:image => @json['image'],
							:author => (@json['author'] == nil || @json['author'].size == 0 || @json['author'] == 'nobody'? @author : @json['author']),
							:conditions => @json['conditions'],
							:group => @json['group']
						  })
		level.save
		@response = {:number => level.number, :author => level.author, :version => version, :id => level.id}

		Level.clear_cache()
	end
end