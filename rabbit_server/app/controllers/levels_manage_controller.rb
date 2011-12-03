class LevelsManageController < BaseController
	def process
		raise AuthError, "Wrong admin password" unless check_password

		case @json['operation']
			when 'create'
				create
			else
				raise MethodError, "Undefined submethod '#{@json['operation']}'"
		end
	end

private
	def check_password
		password = @json['password']
		if password == 'Kk0Tte888'
			@author = 'kate'
			true
		elsif password == 'prevent6seven'
			@author = 'pav'
			true
		elsif DEVELOPMENT
			@author = 'nobody'
			true
		else
			false
		end
	end

	def create
		# Левел с максимальной версией
		head_level = Level.find(:first, :conditions => "number = #{@json['number']}", :order => "version desc")
		version = (head_level ? head_level.version + 1 : 0)
		level = Level.new({
							:number => @json['number'],
							:description => @json['description'],
							:version => version,
							:width => @json['width'],
							:height => @json['height'],
							:image => @json['image'],
							:author => (@json['author'] == nil || @json['author'].size == 0 || @json['author'] == 'nobody'? @author : @json['author']),
							:conditions => @json['conditions'],
							:group => @json['group']
						  })
		level.save
		@response = {:number => level.number, :author => level.author, :version => version, :id => level.id}

		Level.clear_cache()
	end
end