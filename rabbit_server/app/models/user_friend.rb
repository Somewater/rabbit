class UserFriend < ActiveRecord::Base

	belongs_to :user, :foreign_key => 'user_uid', :primary_key => 'uid',  :class_name => 'User', :select => User::SHORT_SELECT
	belongs_to :friend, :foreign_key => 'friend_uid', :primary_key => 'uid', :class_name => 'User', :select => User::SHORT_SELECT

end