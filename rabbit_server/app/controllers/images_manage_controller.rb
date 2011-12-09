class ImagesManageController < BaseController

	def initialize(p)
		@request = p
		super(p)
	end

	def process
		raise AuthError, "Wrong admin password" unless check_password

		operation = @params['operation']
		@file = @params['file_my_name'][:tempfile]
		return
		case operation
			when 'create'
				create
			else
				raise MethodError, "Undefined submethod '#{operation}'"
		end
	end
	
	def call
		@params['file_my_name'][:head]
=begin
		Content-Disposition: form-data; foo="bar"; name="file_my_name"; filename="post.jpg"
		Content-Type: image/jpeg
=end		
		[200, { "Content-Type" => "image/png" }, @file.read]
	end
	
	def authorization params
		true #todo: потом впилить проверку
	end
	def parce params
		true #todo: потом впилить проверку
	end

private
	def check_password
		return true # todo: потом впилить проверку
		password = @params['password']
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
		name =  file.original_filename
    directory = "#{PUBLIC_DIR}/asd"
    # create the file path
    path = File.join(directory, name)
    # write the file
    File.open(path, "wb") { |f| f.write(file.read) }
	end
	
	def get_property(name)
		head = @params['file_my_name'][:head]	
		match = Regexp.new("#{name}=\"(.+)\"").match(s)
		return match[1] if match
		nil
	end
end
