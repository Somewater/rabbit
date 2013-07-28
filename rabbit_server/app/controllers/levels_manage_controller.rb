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
			admin_user.level?(@json['number'])
			@author = admin_user.user.login
			true
		else
			false
		end
	end

	def create
		# Левел с максимальной версией
		level = Level.create_level(@json['number'], @json, @author)
		@response = {:number => level.number, :author => level.author, :version => level.version, :id => level.id}
	end
end
