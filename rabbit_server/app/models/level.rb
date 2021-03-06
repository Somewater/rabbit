class Level < ActiveRecord::Base
	attr_accessor :head # является ли левел ведущим (т.е. именно он применяется при генерации xml)
	
	@@all_head = nil
	@@all_head_by_number = nil
	@@cache = nil
	
	def to_xml
		formatted_conditions = ''
		conditions.each_line{|line| formatted_conditions += (formatted_conditions.size>0 ? "\t#{line}" : line)} if conditions

		formatted_group = ''
		group.each_line{|line| formatted_group += (formatted_group.size>0 ? "\t#{line}" : line)} if group

"<level id=\"#{id}\" version=\"#{version}\">
	<description>#{description}</description>
	<number>#{number}</number>
	<author>#{author}</author>
	<width>#{width}</width>
	<height>#{height}</height>
	<image>#{image}</image>
	#{formatted_conditions}
	#{formatted_group}
</level>"
	end

	def conditions_to_hash
		unless @conditions_to_hash
			@conditions_to_hash = {}
			conditions = REXML::Document.new(self.conditions)
			conditions.children[0].each{|elem| @conditions_to_hash[elem.name] = elem.get_text.to_s.to_i if elem.is_a? REXML::Element }
		end
		@conditions_to_hash
	end

	def story
		Story.by_level_number(self.number)
	end

	# возвратить все "ведущие" уровни
	def self.all_head
		generate_all_head unless @@all_head
		@@all_head
	end

	# возвратить все "ведущие" уровни
	def self.all_head_by_number
		generate_all_head unless @@all_head_by_number
		@@all_head_by_number
	end

	# вычисляется другими классами, но хранится в текущем классе
	def cache
		@cache = {} unless @cache
		@cache
	end
	def self.cache
		@@cache = {} unless @@cache
		@@cache
	end

	def self.by_number(number)
		lvl = self.all_head_by_number[number]
		raise FormatError, "Undefined level number=#{number}" unless lvl
		lvl
	end

	def self.clear_cache
		@@all_head = nil
		@@all_head_by_number = nil
		@@cache = nil
	end

	def self.generate_all_head
		@@all_head = []
		@@all_head_by_number = {}

		added = {}
		levels = Level.all(:order => 'number, version DESC', :conditions => 'enabled = TRUE AND visible = TRUE')
		levels.each do |lvl|
			unless added[lvl.number]
				@@all_head << lvl
				@@all_head_by_number[lvl.number] = lvl
				added[lvl.number] = true
			end
		end
  end

  def self.create_level(number, level_hash, author)
    # Левел с максимальной версией
    head_level = Level.find(:first, :conditions => "number = #{number}", :order => "version desc")
    version = (head_level ? head_level.version + 1 : 0)
    level = Level.new({
                          :number => number,
                          :description => level_hash['description'],
                          :version => version,
                          :enabled => true,
                          :visible => true,
                          :width => level_hash['width'],
                          :height => level_hash['height'],
                          :image => level_hash['image'],
                          :author => (level_hash['author'] == nil || level_hash['author'].size == 0 || level_hash['author'] == 'nobody'? author : level_hash['author']),
                          :conditions => level_hash['conditions'],
                          :group => level_hash['group']
                      })
    level.save
    Level.clear_cache()
    level
  end
end