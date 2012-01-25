class AdminController

	def call request
		@request = request

		admin_user = authorized(request)
		return [200, {"Content-Type" => "text/html; charset=UTF-8"},
							  "<html><body><form method='post'><table>
							  <tr><td>Login:</td><td><input name='login'></input></td></tr>
							  <tr><td>Password:</td><td><input name='password' type='password'></input></td></tr>
							  <tr><td></td><td><input type='submit' value='OK'></input></td></tr>
							  </table></form></body></html>"] unless admin_user.authorized?
		if(admin_user.authorized? == :login)
			resp = process(admin_user)
			[200, admin_user.generate_cookie, resp]
		elsif admin_user.authorized? == :success
			resp = process(admin_user)
			[200, {"Content-Type" => "text/html; charset=UTF-8"}, resp]
		else
			raise FormatError, "Undefined authentification status #{admin_user.authorized?}"
		end
	end

	def process(admin_user)
		method = @request.path
		method = method[7, method.size - 1] if method  # cut "/admin/"
		case method
			when /^errors/
				ErrorsAdminController.new(@request, admin_user).call
			when /^levels/
				LevelsAdminController.new(@request, admin_user).call
			when /^stories/
				StoriesAdminController.new(@request, admin_user).call
			when /^logs/
				LogsAdminController.new(@request, admin_user).call
			when /^users/
				UsersAdminController.new(@request, admin_user).call
			when /^admins/
				AdminsAdminController.new(@request, admin_user).call
			when /^vk\/notify/
				VkNotifyAdminController.new(@request, admin_user).call
			when /stat/
				StatAdminController.new(@request, admin_user).call
			when /config/
				ConfAdminController.new(@request, admin_user).call
			else
				IndexAdminController.new(@request, admin_user).call
		end
	end

	class Base
		def initialize request, admin_user
			@request = request
			@admin_user = admin_user
			check_permissions()

			@command = request.path
			@command = @command[7, @command.size - 1] if @command  # cut "/admin/"
		end

		def request
			@request
		end

		# хелпер, оборачивает результат в <html>
		def html args = nil
			args = {} unless args
			"<html><head><title>#{args[:title]}</title></head><body>#{yield}</body></html>"
		end

		# хелпер для создания тегов
		def tag name, parameters = nil
			args = ""
			parameters.each{|key, value| args += " #{key}=\"#{value}\"" } if parameters
			"<#{name}#{args}>#{(block_given? ? yield : parameters[:value])}</#{name}>"
		end

		def template text
			require "erb"
			erb = ERB.new text
			erb.result(self_binding)
		end

		def self_binding
		   binding
		end

		def call
			'empty'
		end
		
		protected
		def check_permissions()
			raise UnimplementedError, "Function must overriden"
		end
	end

private
	def authorized request
		AdminUser.new(request)
	end
end

