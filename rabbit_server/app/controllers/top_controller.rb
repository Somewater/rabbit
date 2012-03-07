class TopController < BaseController

	@@cache = nil
	@@cache_version = 0

	# просто выдает всю информацию, предварительно сохраненную в TopManager
	def process
		net = @params['net'].to_i
		# если надо, обновить кэш
		if(@@cache == nil || @@cache[net] == nil || @@cache_version != TopManager.instance.top_version)
			@@cache_version = TopManager.instance.top_version
			@@cache = {} unless @@cache
			@@cache[net] = {} unless @@cache[net]
			TopManager::TOP_NAMES.each do |top_name|
				top = TopManager.instance.get_tops(net, top_name)
				top_data = ""
				top.each{|t| top_data << t[:uid].to_s << ';' << t[:value].to_s << ';' }
				@@cache[net][top_name] = top_data # todo: при необходимости ужать данные (value -> v, uid -> u)
			end
		end
		@response = @@cache[net]
	end

end