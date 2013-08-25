class UserFriend < ActiveRecord::Base

	belongs_to :user, :foreign_key => 'user_uid'
	belongs_to :friend, :foreign_key => 'friend_uid'

end