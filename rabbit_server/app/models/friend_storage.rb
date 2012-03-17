class FriendStorage < ActiveRecord::Base
	def friends
		self['friends'].to_s.split(',')
	end

	def friends=(array)
		self['friends'] = array ? array.join(',') : nil
	end

	def rewarded
		self['rewarded'].to_s.split(',')
	end

	def rewarded=(array)
		self['rewarded'] = array ? array.join(',') : nil
	end

	def include?(user)
		user = user.uid if user.is_a?(User)
		friends.include?(user)
	end

	def rewarded?(user)
		user = user.uid if user.is_a?(User)
		rewarded.include?(user)
	end

	def self.find_by_user(user, net = nil)
		user,net = user.uid,user.net if user.is_a?(User)
		self.where(:uid => user, :net => net).first
	end

	def self.create_from(user)
		storage = FriendStorage.new
		storage.uid = user.uid
		storage.net = user.net
		storage
	end
end