class RewardManager

	TYPE_FAST_TIME = 	'fast_time'
	TYPE_ALL_CARROT = 	'all_carrots'
	TYPE_CARROT_PACK = 	'carrot_pack'
	TYPE_SPECIAL = 		'special'

	@@instance = nil

	class Reward
		attr_reader :id, :type, :degree, :index

		def initialize(attrs)
			@id = attrs['id'].to_i
			@type = attrs['type']
			@degree = attrs['degree'].to_i
			@index = attrs['index'].to_i
		end
	end

	def initialize
		@rewards_by_type = {}
		@rewards_by_id = {}
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

	# массив всех ревардов, отсортированных по id
	def rewards
		@rewards
	end

private
	def read_files
		require 'rexml/document'
		xml = REXML::Document.new File.read("#{PUBLIC_DIR}/Rewards.xml")
		xml.each_element 'reward/template' do |reward_xml|
			reward = Reward.new(reward_xml.attributes)
			@rewards_by_type[reward.type] = [] unless @rewards_by_type[reward.type]
			@rewards_by_type[reward.type] << reward
			raise FormatError, "Double rewards id ##{reward.id}" if @rewards_by_id[reward.id]
			@rewards_by_id[reward.id] = reward
			@rewards << reward
		end

		@rewards.sort!{|r1, r2| r1.id <=> r2.id }
		@rewards_by_type.each do |type, rewards|
			rewards.sort! do |r1, r2|
				if r1.degree == r2.degree
					r1.index <=> r2.index
				else
					r1.degree <=> r2.degree
				end
			end
		end
	end
end