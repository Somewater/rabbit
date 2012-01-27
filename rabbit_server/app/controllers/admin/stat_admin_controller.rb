class StatAdminController < AdminController::Base
	STAT_PATH = '/admin/stat'
	
	Time::DATE_FORMATS[:dd_mm_yyyy] = "%d.%m.%Y"

	def check_permissions()
		raise AuthError, "Illegal operation" unless @admin_user.can?(AdminUser::PERMISSION_STAT_VIEW)
	end

	def self_binding
		binding
	end

	def call
		@names = Stat.select('name').group('name').map{|s| s.name }
		
		@opt = @request['opt'] || {}
		
		@opt['names'] ||= @request['names'] || []
		@opt['names'] = @opt['names'].split(',')	unless @opt['names'].is_a? Array
		
		@opt['from'] = string_date_to_time(@opt['from'], Time.new(2012,1,1))
		@opt['to'] = string_date_to_time(@opt['to'], Time.new)
		

		if(@opt['names'] && @opt['names'].size > 0)
			#@name = @request['name']
			#@stats = Stat.all(:conditions => ['name = ?', @name], :order => 'time DESC')
			@stats =  Stat.find_by_params(@opt['names'], @opt['from'], @opt['to'])
		end

		template(File.read("#{TEMPLATE_ROOT}/admin/stat_admin_show.erb"))
	end
	
	# date - timestamp (sec), array [<day>,<month>,<year>], string "28.12.2011"
	def string_date_to_time(date, default)
		return nil unless date
		return Time.at(date.to_s.to_i) if (date.to_s =~ /^\d{9,11}$/) == 0
		date = date.split(',').map{|i| i.to_i} if date.is_a? String
		date = Time.new(date[0] || default.day, date[1] || default.month, date[2] || default.year) if date.is_a? Array && date.size > 0
		date
	end
end
