class XmlController
	@@instance = nil

	def initialize
		# todo: прочитать и обработать Description.xml аналогично логике клиента
		@calculate_reward_size_cache = {}
	end

	def self.instance
		unless @@instance
			@@instance = XmlController.new
		end
		@@instance
	end

	def carrot_all(level)
		unless level.cache['carrot_all']
			raise 'Unimplemented calculation logic: all carrot from level'
		end
		level.cache['carrot_all'].to_i
	end

	def carrot_max(level)
		if(level.conditions_to_hash['carrotMax'])
			level.conditions_to_hash['carrotMax'].to_i
		else
			carrot_all(level)
		end
	end

	def carrot_middle(level)
		if(level.conditions_to_hash['carrotMiddle'])
			level.conditions_to_hash['carrotMiddle'].to_i
		else
			carrot_max(level) - 1
		end
	end

	def carrot_min(level)
		if(level.conditions_to_hash['carrotMin'])
			level.conditions_to_hash['carrotMin'].to_i
		elsif(level.conditions_to_hash['carrot'])
			level.conditions_to_hash['carrot'].to_i
		else
			carrot_middle(level) - 1
		end
	end

=begin
	 Просчитать размер реварда, который он занимает на поле
	 @param reward_id
	 @return {:x => 1, :y => 1}
=end
	def reward_size(reward_id)
		raise 'Dont`t touch this heavy function'
		if(@calculate_reward_size_cache[reward_id] == nil)
			template = RewardManager.instance.get_xml_by_id(reward_id);
			result = @calculate_reward_size_cache[reward_id] = {:x => 1, :y => 1};
			iterate_components(template) do |component|
				if(component.attributes['name'] == 'Spatial')
					component.each_element('size') do |size|
						size.each_element('x'){|x| result.x = x.to_i if x && x.to_s.size > 0}
						size.each_element('y'){|y| result.y = y.to_i if y && y.to_s.size > 0}
					end
					true;
				else
					false;
				end
			end
		end
		@calculate_reward_size_cache[reward_id].dup;
	end

	def iterate_components(template_xml)
		template_xml.children[0].each do |component_xml|
			res = yield(component_xml) if block_given?
			break if res
		end
	end
end