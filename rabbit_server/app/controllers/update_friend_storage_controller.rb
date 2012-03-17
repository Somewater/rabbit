class UpdateFriendStorageController < BaseUserController

	# обновить список друзей пользователя
	def process
		friends = @json['friends']
		raise FormatError, 'Wrong friend data format' unless friends && friends.is_a?(Array)
		friends_storage = FriendStorage.find_by_user(@user)
		friends_storage = FriendStorage.create_from(@user) unless friends_storage
		friends_storage.friends = friends
		friends_storage.save
	end
end