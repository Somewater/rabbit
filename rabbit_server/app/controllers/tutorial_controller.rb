# инкрементить счетчик тьюториала
class TutorialController < BaseUserController

	# инкрементить счетчик тьюториала, делать проверки на некорректность присваемого значения
	def process
		tutorial = @json['tutorial'].to_i
		user_tutorial = @user.tutorial.to_i
		raise LogicError, "Tutorial must only increment. User totorial = #{user_tutorial}" if tutorial <= user_tutorial
		@user.tutorial = tutorial
		@response['user'] = @user.to_json
	end
end