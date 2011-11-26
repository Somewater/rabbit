# Достает из базы юзера, для взаимодействия
class BaseUserController < BaseController

	def authorized
		@user = User.where(:uid => @params['uid'], :net => @params['net'])[0]
		raise AuthError, 'User not found' unless @user
	end

	def save_data()
		# save user
		save(@user)
		super
	end
end