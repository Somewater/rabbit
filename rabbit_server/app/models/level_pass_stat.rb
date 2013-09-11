class LevelPassStat < ActiveRecord::Base
	def self.add(data)
		l = LevelPassStat.new
		l.uid = data['uid']

		l.level = data['level'].to_i
		l.time = data['time'].to_i
		l.carrots = data['carrots'].to_i
		l.stars = data['stars'].to_i

		l.powerups = data['powerups'] if data['powerups'].to_s.size > 0
		l.flag = data['flag']

		l.success = data['success']
		l.first = data['first']

		l.save
	end
end