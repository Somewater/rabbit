class Offer
	attr_reader :x, :y, :level, :id
	attr_accessor :type

	def initialize(x, y, level, id = nil)
		@x = x.to_i
		@y = y.to_i
		@level = level.to_i
		@type = nil
		if(id)
			@id = id.to_s
		else
			@id = OfferManager.params_to_id(x, y, level)
		end
	end

	def to_xml
"<offer id=\"#{@id}\">
	<x>#{@x}</x>
	<y>#{@y}</y>\n" <<
	(@type ? "	<type>#{@type}</type>\n" : '') <<
"	<level>#{@level}</level>
</offer>"
	end
end