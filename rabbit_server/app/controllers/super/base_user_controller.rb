# Достает из базы юзера, для взаимодействия
class BaseUserController < BaseController

	def initialize(params)
		super(params)

		# save user
		@user.save
	end

	def authorized
		@user = User.where(:uid => @params['uid'], :net => @params['net'])[0]
		raise AuthError, 'User not found' unless @user
	end
end