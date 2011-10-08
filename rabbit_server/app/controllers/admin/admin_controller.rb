class AdminController

	def call request
		@request = request

		auth = authorized(request)
		return [200, {"Content-Type" => "text/html; charset=UTF-8"},
							  "<html><body><form method='post'><table>
							  <tr><td>Login:</td><td><input name='login'></input></td></tr>
							  <tr><td>Password:</td><td><input name='pass' type='password'></input></td></tr>
							  <tr><td></td><td><input type='submit' value='OK'></input></td></tr>
							  </table></form></body></html>"] unless auth
		if(auth == :login)
			resp = process()
			[200, generate_cookie, resp]
		elsif auth == :success
			resp = process()
			[200, {"Content-Type" => "text/html; charset=UTF-8"}, resp]
		end
	end

	def process
		method = @request.path
		method = method[7, method.size - 1] if method  # cut "/admin/"
		case method
			when /^errors/
				ErrorsAdminController.new(@request).call
			when /^levels/
				LevelsAdminController.new(@request).call
			else
				Base.new(@request).call
		end
	end

	class Base
		def initialize request
			@request = request

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
			html do
				r = ""
				r += tag "p" do
					tag "a", :href => '/admin/errors', :value => 'errors'
				end
				r += tag "p" do
					tag "a", :href => '/admin/levels', :value => 'levels'
				end
				r
			end
		end
	end

private
	def authorized request
		require 'digest/md5'
		if request.cookies['error-login-hash'] == generate_hash
			:success
		elsif request['login'] && (
				(request['login'].downcase == 'kate' && Digest::MD5.hexdigest(request['pass']) == '7a57ccbb278a3eede95d4a341cf93813') ||
				(request['login'].downcase == 'dev' && Digest::MD5.hexdigest(request['pass']) == '8f00d0955e699c1ce25d2c1ea76f5330')
				)
			:login
		else
			nil
		end
	end

	def generate_hash
		Digest::MD5.hexdigest("hello#{(Time.new.yday/7).to_s}world")
	end

	def generate_cookie
		{'Content-Type' => 'text/html; charset=UTF-8', 'Set-Cookie' => "error-login-hash=#{generate_hash}; path=/admin"}
	end
end

