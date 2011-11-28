class RewardManager

	@@instance = nil

	def initialize
		@rewards_by_type = {}
		@rewards_by_id = {}
		@xml_by_id = {}
		@rewards = []
		read_files
	end

	def self.instance
		unless @@instance
			@@instance = RewardManager.new
		end
		@@instance
	end

	# Массив ревардов одного типа
	def get_by_type(type)
		@rewards_by_type[type.to_s] or []
	end

	# Ревард с заданным id
	def get_by_id(id)
		@rewards_by_id[id.to_i]
	end

	# XML реварда с заданным id
	def get_xml_by_id(id)
		@xml_by_id[id.to_i]
	end

	# массив всех ревардов, отсортированных по id
	def rewards
		@rewards
	end

private
	def read_files
		xml = REXML::Document.new File.read("#{PUBLIC_DIR}/Rewards.xml")
		xml.each_element 'reward/template' do |reward_xml|
			reward = Reward.new(reward_xml.attributes)
			@rewards_by_type[reward.type] = [] unless @rewards_by_type[reward.type]
			@rewards_by_type[reward.type] << reward
			raise FormatError, "Double rewards id ##{reward.id}" if @rewards_by_id[reward.id]
			@rewards_by_id[reward.id] = reward
			@xml_by_id[reward.id] = reward_xml
			@rewards << reward
		end

		@rewards.sort!{|r1, r2| r1.id <=> r2.id }
		@rewards_by_type.each do |type, rewards|
			rewards.sort! do |r1, r2|
				if r1.degree == r2.degree
					r1.id <=> r2.id
				else
					r1.degree <=> r2.degree
				end
			end
		end
	end
end