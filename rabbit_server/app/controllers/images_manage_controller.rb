class ImagesManageController < BaseController

	def authorization params
		raise AuthError, "Wrong admin password" unless check_password
		true
	end

	def process
		operation = get_property('operation') || 'create'
		case operation
			when 'create'
				create(@params['file_my_name'][:tempfile])
			else
				raise MethodError, "Undefined submethod '#{operation}'"
		end
	end
	
	def call
		[200, { "Content-Type" => "image/png" }, @file ? @file.read : 'ok']
	end
	
	def parce params
		true #todo: потом впилить проверку
	end

private
	def check_password
		password = get_property('password')
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

	def create(file)
		@file = file
		name =  "#{get_property('type')}_#{get_property('id')}.jpg"
    	directory = "#{ROOT}/tmp/#{get_property('folder') || 'images'}"
    	# create the file path
    	path = File.join(directory, name)
		Dir.mkdir(directory) unless Dir.exist?(directory)
    	# write the file
    	File.open(path, "wb") { |f| f.write(file.read) }
	end
	
	def get_property(name)
		head = @params['file_my_name'][:head]	
		match = Regexp.new("#{name}=\"([^\"]+)\"").match(head)
		return match[1] if match
		nil
	end
end
