class NewUserStat < ActiveRecord::Base
	def self.add(data)
		n = NewUserStat.new
		n.uid = data['uid']

		n.referer = data['referer'] if data['referer'].to_s.size > 0
		n.source = data['source'] if data['source'].to_s.size > 0
		n.adv = data['adv'] if data['adv'].to_s.size > 0

		n.save
	end
end