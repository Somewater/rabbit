require "digest/md5"

class AdminUser

	PERMISSION_LEVEL_SAVE = 1
	PERMISSION_LEVEL_TRACKER = 1
	PERMISSION_USER_TRACKER = 2
	PERMISSION_LOG_VIEW = 4
	PERMISSION_ERROR_TRACKER = 8

	COOKIE_NAME = 'rabbit-admin'

	# simple_schema - значит есть только password и на его основе надо выяснить юзера
	def initialize(request)
		@params = request['params'] || request.params
		@cookies = request['cookies'] || request.cookies
		@user = nil #{'login', 'password'}
		@authorized = nil
		process()
	end
	
	def user
		@user
	end

	def permissions
		if(@user)
			@user.permissions.to_i
		else
			0
		end
	end

	def can?(perm_bit)
		perm_bit.to_i & self.permissions > 0
	end

	def level?(level)
		level = level.number if level.is_a?(Level)
		level = level.to_i
		raise AuthError, "Illegal level number #{level}. Must between #{@user.level_low}-#{@user.level_high}" \
			 					if @user.level_low > level || @user.level_high < level
	end
	
	# есть ли такой юзер в базе (nil, :login, :success); где :login авторизация по логин-пароль, :success - авторизация по coocke
	def authorized?
		@authorized
	end
	
	# команда выставить куку для браузера
	def generate_cookie
		{'Content-Type' => 'text/html; charset=UTF-8', 'Set-Cookie' => "#{COOKIE_NAME}=#{generate_hash}; path=/admin"}
	end
	
	private
	# найти в базе юзера, на основе login-password
	def process()
		if request_coockie_hash && request_coockie_hash == generate_hash(find_user_by_login(request_login))
			@user = find_user_by_login(request_login)
			raise AuthError, "User login #{login} not exist" unless @user
			@authorized = :success
			true
		elsif request_password && @params['login']
			@user = find_user_by_login(@params['login'])
			raise AuthError, "Wrong login or password" if @user == nil || @user.password != request_password
			@authorized = :login
			true
		else
			nil
		end
	end
	
	def find_user_by_login(login)
		(Admin.where(:login => login.to_s) || []).first
	end
	
	def request_login
		if @params['login']
			@params['login']
		elsif request_coockie_hash
			pair = request_coockie_hash.split('-')
			return nil if pair.size != 2
			pair[0]
		else
			nil
		end 
	end
	
	def request_password
		@params['password']
	end
	
	def request_coockie_hash
		@cookies[COOKIE_NAME]
	end
	
	def encode(str)
		Digest::MD5.hexdigest(str)
	end
	
	def generate_hash(user = nil)
		user = @user unless user
		raise AuthError, 'User must be authorized for some way' unless user
		hash = "#{user.login}-"
		hash += encode("hello#{(Application.time.yday/7).to_s}world#{user.password}")
		hash
	end
end
