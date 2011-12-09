# Достает из базы юзера, для взаимодействия
class BaseUserController < BaseController

	def authorized
		@user = User.find_by_uid(@params['uid'], @params['net'])
		raise AuthError, 'User not found' unless @user
	end

	def save_data()
		# save user
		save(@user)
		super
	end
end