# инкрементить счетчик тьюториала
class TutorialController < BaseUserController

	# инкрементить счетчик тьюториала, делать проверки на некорректность присваемого значения
	def process
		tutorial = @json['tutorial'].to_i
		user_tutorial = @user.tutorial.to_i
		if tutorial <= user_tutorial
			# вместо трова ошибки просто выдаем такой ответ. Иначе весь лог заспамится ошибками про тьюториал
			@response['status'] = "Tutorial must only increment. User totorial = #{user_tutorial}"
		else
			@user.tutorial = tutorial
			@response['user'] = @user.to_json
		end
	end
end