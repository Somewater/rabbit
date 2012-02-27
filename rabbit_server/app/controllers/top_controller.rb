class TopController < BaseController

	@@cache = nil
	@@cache_version = 0

	# просто выдает всю информацию, предварительно сохраненную в TopManager
	def process
		# если надо, обновить кэш
		if(@@cache == nil || @@cache_version != TopManager.instance.top_version)
			@@cache_version = TopManager.instance.top_version
			@@cache = {}
			TopManager::TOP_NAMES.each do |top_name|
				top = TopManager.instance.get_tops(@params['net'], top_name)
				top_data = ""
				top.each{|t| top_data << t[:uid].to_s << ';' << t[:value].to_s << ';' }
				@@cache[top_name] = top_data # todo: при необходимости ужать данные (value -> v, uid -> u)
			end
		end
		@response = @@cache
	end

end