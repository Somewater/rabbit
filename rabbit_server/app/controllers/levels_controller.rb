class LevelsController < BaseController
	def call
		return "E_AUTH" unless check_password

		case @json['operation']
			when 'create'
				create
			else
				raise "E_METHOD"
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
							:author => (@json['author'] == nil || @json['author'].size == 0 || @json['author'] == 'nobody'? @author : @json['author']),
							:conditions => @json['conditions'],
							:group => @json['group']
						  })
		level.save
		self.generate :number => level.number, :author => level.author, :version => version, :id => level.id
	end

	def self.view
		res = ""
		(Level.all || []).each do |l|
			res += "LEVEL ##{l.number} version=#{l.version} author=\"#{l.author}\" size=#{l.width}x#{l.height}\n" +
					"DESCRIPTION:\n#{l.description}\n\nCONDITIONS:\n#{l.conditions}\n\nGROUP\n:#{l.group}\n\n\n\n"
		end
		[200, {"Content-Type" => "text; charset=UTF-8"}, res]
	end
end