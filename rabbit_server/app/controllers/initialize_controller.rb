class InitializeController < BaseUserController

	def authorized
		if @params['uid'] && @params['uid'].to_s.size > 0 && @params['uid'].to_s != 'null'
			# базовая реализация поиска юзера
			super
		else
			# сначала присвоим ранее не применяемый :uid
			@json['user']['uid'] = ((User.maximum(:uid) || 0).to_i + 1).to_s
			# необходимые поля для создания: :net, :first_name, :last_name
		   	@user = User.new(@json['user'])
			# добавляем в ответ информацию о созданном пользователе
			@response['user'] = {:uid => @user.uid, :new => true}

			#todo: проверки и выдача бонусов referrer
		end
	end

	def process
		@response['session'] = true
	end
end