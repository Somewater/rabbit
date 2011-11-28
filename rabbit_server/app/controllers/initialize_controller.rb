class InitializeController < BaseUserController

	def authorized
		if @params['uid'] && @params['uid'].to_s.size > 0 && @params['uid'].to_s != 'null'
			# базовая реализация поиска юзера
			begin
				super
				check_familiar_reward()
			rescue AuthError
				# создать юзера
				create_user()
				check_referer_reward()
			end
		else
			# сначала присвоим ранее не применяемый :uid
			@json['user']['uid'] = ((User.maximum(:uid) || 0).to_i + 1).to_s
			create_user()
			check_referer_reward()
		end
	end

	def process
		user = (@response['user'] ||= {})
		user.merge!(@user.to_json)

		@response['session'] = true
	end

	private
	def create_user
		# необходимые поля для создания: :uid, :net (, :first_name, :last_name)
		@user = User.new(@json['user'])
		# добавляем в ответ информацию о созданном пользователе
		@response['user'] = {:uid => @user.uid, :new => true}
	end

	def check_referer_reward
		#todo: проверки и выдача бонусов referrer
	end

	def check_familiar_reward
		#todo: проверки и выдача бонусов familiar
	end
end