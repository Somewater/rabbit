class UserInfoController < BaseUserController
	# прогнать левел инстанс через server_logic и выдать ответ клиенту
	def process
		raise FormatError, "Request has bad format" unless @json['user'] && @json['user']['uid']
		@personage = User.find_by_uid(@json['user']['uid'], @params['net'])
		raise LogicError, "User uid #{@json['user']['uid']} not found" unless @personage

		@response['info'] = @personage.to_json

		if(@json['friend'])
			storage = FriendStorage.find_by_user(@personage)
			if(storage && storage.include?(@user))
				@response['friend'] = true
				# момент следующего сбора, unixtime, по серверу (секунды)
				if(storage.last_day != Application.time.yday || !storage.rewarded?(@user))
					@response['next_reward_time'] = 0 # т.е. уже в момент генерации ответа на сервере, можно было совершить сбор
				else
					# очевидно, что на момент генерации ответа, сбор был невозможен, но может быть очень скоро появится такая возможность?
					@response['next_reward_time'] = (DateTime.now.midnight + 1.day).to_i
				end
			else
				@response['friend'] = false
			end
		end
	end
end